package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"math"
	"net"
	"net/http"
	"net/http/httptrace"
	"net/netip"
	"net/url"
	"strconv"
	"strings"
	"time"

	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
)

const nodeQualityBodyLimit = 256 * 1024
const nodeQualityProbeTimeout = 6 * time.Second

// A manual inspection feature, not a forwarding hook or periodic health check.
var nodeQualitySlots = make(chan struct{}, 2)

type NodeQualityRequest struct {
	ProxyName   string   `json:"proxy-name"`
	Providers   []string `json:"providers"`
	QualityURLs []string `json:"quality-urls,omitempty"`
}

type NodeQualityProbe struct {
	Provider      string `json:"provider"`
	Status        string `json:"status"`
	Reason        string `json:"reason,omitempty"`
	EgressIP      string `json:"egressIp,omitempty"`
	Colo          string `json:"colo,omitempty"`
	Country       string `json:"country,omitempty"`
	TTFBMs        *int64 `json:"ttfbMs,omitempty"`
	RiskScore     *int   `json:"riskScore,omitempty"`
	IsResidential *bool  `json:"isResidential,omitempty"`
}

type NodeQualityResult struct {
	SchemaVersion int              `json:"schemaVersion"`
	Source        string           `json:"source"`
	ProxyName     string           `json:"proxyName"`
	SampledAt     string           `json:"sampledAt"`
	Network       NodeQualityProbe `json:"network"`
	Quality       NodeQualityProbe `json:"quality"`
}

func parseNodeQualityRequest(data any) (NodeQualityRequest, error) {
	var request NodeQualityRequest
	raw, ok := data.(string)
	if !ok || len(raw) > 4096 {
		return request, errors.New("invalid node quality request")
	}
	decoder := json.NewDecoder(strings.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		return request, errors.New("invalid node quality request")
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		return request, errors.New("invalid node quality request")
	}
	if request.ProxyName == "" || len(request.ProxyName) > 1024 ||
		len(request.Providers) == 0 || len(request.Providers) > 2 ||
		len(request.QualityURLs) > 1 {
		return request, errors.New("invalid node quality request")
	}
	seen := map[string]bool{}
	hasCustom := false
	for _, provider := range request.Providers {
		switch provider {
		case "cloudflare", "ippure":
		case "custom":
			hasCustom = true
		default:
			return request, errors.New("invalid node quality provider")
		}
		if seen[provider] {
			return request, errors.New("invalid node quality provider")
		}
		seen[provider] = true
	}
	// A custom provider is meaningless without its endpoint, and an endpoint
	// without the provider would silently never be probed.
	if hasCustom != (len(request.QualityURLs) == 1) {
		return request, errors.New("invalid node quality custom URL")
	}
	for _, rawURL := range request.QualityURLs {
		if _, err := validateCustomQualityURL(rawURL); err != nil {
			return request, errors.New("invalid node quality custom URL")
		}
	}
	return request, nil
}

// customQualityIPPlaceholder survives URL parsing unchanged; {ip} itself would
// be percent-encoded in the path before the egress IP is known.
const customQualityIPPlaceholder = "quanclash-ip-placeholder"

// validateCustomQualityURL validates a user-supplied JSON risk endpoint and
// returns it in canonical form. {ip} may appear in the path or query and is
// replaced with the probed egress IP before the request is sent.
//
// The request must stay on a public host over 443 so a custom endpoint cannot
// turn this manual probe into a request to local services or the LAN.
func validateCustomQualityURL(rawURL string) (string, error) {
	if len(rawURL) < 12 || len(rawURL) > 1024 || strings.ContainsAny(rawURL, " \t\r\n\\") {
		return "", errors.New("invalid custom endpoint")
	}
	parsed, err := url.Parse(strings.ReplaceAll(rawURL, "{ip}", customQualityIPPlaceholder))
	if err != nil || parsed.Scheme != "https" || parsed.User != nil ||
		parsed.Fragment != "" || parsed.Opaque != "" || parsed.Hostname() == "" ||
		strings.Contains(parsed.Host, customQualityIPPlaceholder) {
		return "", errors.New("invalid custom endpoint")
	}
	host := strings.ToLower(parsed.Hostname())
	if ip, err := netip.ParseAddr(host); err == nil {
		if !ip.IsGlobalUnicast() || ip.IsPrivate() || ip.IsLoopback() ||
			ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() || ip.IsUnspecified() {
			return "", errors.New("custom endpoint host is not public")
		}
	} else if host == "localhost" || strings.HasSuffix(host, ".localhost") ||
		strings.HasSuffix(host, ".local") || strings.HasSuffix(host, ".internal") {
		return "", errors.New("custom endpoint host is not public")
	}
	port := parsed.Port()
	if port == "" {
		port = "443"
	} else if port != "443" {
		return "", errors.New("custom endpoint port must be 443")
	}
	path := parsed.EscapedPath()
	if path == "" {
		path = "/"
	}
	if path[0] != '/' || len(path) > 512 || strings.Contains(path, "..") {
		return "", errors.New("invalid custom endpoint path")
	}
	if len(parsed.RawQuery) > 512 {
		return "", errors.New("invalid custom endpoint query")
	}
	endpoint := "https://" + net.JoinHostPort(host, port) + path
	if parsed.RawQuery != "" {
		endpoint += "?" + parsed.RawQuery
	}
	return endpoint, nil
}

func qualityProvider(request NodeQualityRequest) string {
	for _, provider := range request.Providers {
		if provider == "custom" {
			return "custom"
		}
	}
	return "ippure"
}

func newNodeQualityResult(request NodeQualityRequest) NodeQualityResult {
	return NodeQualityResult{
		SchemaVersion: 1, Source: "selected-proxy", ProxyName: request.ProxyName,
		SampledAt: time.Now().UTC().Format(time.RFC3339Nano),
		Network:   NodeQualityProbe{Provider: "cloudflare", Status: "not-requested"},
		Quality:   NodeQualityProbe{Provider: qualityProvider(request), Status: "not-requested"},
	}
}

func (result *NodeQualityResult) unavailable(request NodeQualityRequest, reason string) {
	for _, provider := range request.Providers {
		probe := NodeQualityProbe{Provider: provider, Status: "unavailable", Reason: reason}
		if provider == "cloudflare" {
			result.Network = probe
		} else {
			result.Quality = probe
		}
	}
}

// customQualityEndpoint resolves the configured endpoint for a probe, filling
// in the egress IP discovered by the network probe when the URL asks for it.
func customQualityEndpoint(request NodeQualityRequest, egressIP string) (string, error) {
	if len(request.QualityURLs) != 1 {
		return "", errors.New("missing custom endpoint")
	}
	endpoint, err := validateCustomQualityURL(request.QualityURLs[0])
	if err != nil {
		return "", err
	}
	if strings.Contains(endpoint, customQualityIPPlaceholder) {
		ip, err := netip.ParseAddr(egressIP)
		if err != nil || !ip.IsValid() {
			return "", errors.New("egress IP unavailable")
		}
		endpoint = strings.ReplaceAll(endpoint, customQualityIPPlaceholder, ip.Unmap().String())
	}
	return endpoint, nil
}

func nodeQualityConcreteProxy(proxy C.Proxy) bool {
	switch proxy.Type() {
	case C.Selector, C.URLTest, C.Fallback, C.Relay, C.LoadBalance,
		C.Pass, C.PassRule, C.Rematch, C.Compatible, C.Dns, C.Reject, C.RejectDrop:
		return false
	default:
		return true
	}
}

func handleTestNodeQuality(data any) (NodeQualityResult, error) {
	request, err := parseNodeQualityRequest(data)
	if err != nil {
		return NodeQualityResult{}, err
	}
	result := newNodeQualityResult(request)
	runLock.Lock()
	active := isInit && currentConfig != nil
	proxy := tunnel.AllProxies()[request.ProxyName]
	runLock.Unlock()
	if !active {
		result.unavailable(request, "inactive")
		return result, nil
	}
	return testNodeQualityThroughProxy(request, proxy, nodeQualitySlots), nil
}

func testNodeQualityThroughProxy(request NodeQualityRequest, proxy C.Proxy, slots chan struct{}) NodeQualityResult {
	result := newNodeQualityResult(request)
	if proxy == nil {
		result.unavailable(request, "proxy-not-found")
		return result
	}
	// Pin one concrete adapter rather than a mutable/load-balancing group.
	if !nodeQualityConcreteProxy(proxy) {
		result.unavailable(request, "group-not-supported")
		return result
	}
	select {
	case slots <- struct{}{}:
		defer func() { <-slots }()
	default:
		result.unavailable(request, "busy")
		return result
	}
	dial := func(ctx context.Context, metadata *C.Metadata) (net.Conn, error) {
		return proxy.DialContext(ctx, metadata)
	}
	// The network probe runs first even if the caller listed it later: a custom
	// endpoint may need its egress IP for the {ip} placeholder.
	ordered := make([]string, 0, len(request.Providers))
	for _, provider := range request.Providers {
		if provider == "cloudflare" {
			ordered = append(ordered, provider)
		}
	}
	for _, provider := range request.Providers {
		if provider != "cloudflare" {
			ordered = append(ordered, provider)
		}
	}
	for _, provider := range ordered {
		probe := probeNodeQuality(context.Background(), provider, dial, request, result.Network.EgressIP)
		if provider == "cloudflare" {
			result.Network = probe
		} else {
			result.Quality = probe
		}
	}
	return result
}

type nodeQualityDial func(context.Context, *C.Metadata) (net.Conn, error)

// nodeQualityTarget returns the pinned host and full endpoint URL for a probe.
func nodeQualityTarget(request NodeQualityRequest, provider, egressIP string) (string, string, bool) {
	switch provider {
	case "cloudflare":
		return "www.cloudflare.com", "https://www.cloudflare.com/cdn-cgi/trace", true
	case "ippure":
		return "my.ippure.com", "https://my.ippure.com/v1/info", true
	case "custom":
		endpoint, err := customQualityEndpoint(request, egressIP)
		if err != nil {
			return "", "", false
		}
		parsed, err := url.Parse(endpoint)
		if err != nil {
			return "", "", false
		}
		return parsed.Hostname(), endpoint, true
	default:
		return "", "", false
	}
}

func nodeQualityTransport(host string, dial nodeQualityDial) *http.Transport {
	return &http.Transport{
		// Do not inherit HTTP_PROXY or resolve the target through net.DefaultResolver.
		// The chosen adapter owns its DNS/bootstrap requirements, just as in URLTest.
		Proxy: nil, DisableKeepAlives: true, DisableCompression: true,
		MaxResponseHeaderBytes: 16 * 1024, TLSHandshakeTimeout: nodeQualityProbeTimeout,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			if network != "tcp" || addr != net.JoinHostPort(host, "443") {
				return nil, errors.New("unexpected node quality destination")
			}
			metadata := &C.Metadata{NetWork: C.TCP, Type: C.INNER}
			if err := metadata.SetRemoteAddress(addr); err != nil {
				return nil, errors.New("invalid node quality destination")
			}
			return dial(ctx, metadata)
		},
	}
}

func probeNodeQuality(parent context.Context, provider string, dial nodeQualityDial, request NodeQualityRequest, egressIP string) NodeQualityProbe {
	host, endpoint, ok := nodeQualityTarget(request, provider, egressIP)
	if !ok {
		reason := "unsupported-provider"
		if provider == "custom" {
			reason = "invalid-endpoint"
		}
		return NodeQualityProbe{Provider: provider, Status: "unavailable", Reason: reason}
	}
	transport := nodeQualityTransport(host, dial)
	defer transport.CloseIdleConnections()
	client := &http.Client{
		Transport:     transport,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	ctx, cancel := context.WithTimeout(parent, nodeQualityProbeTimeout)
	defer cancel()
	return fetchNodeQuality(ctx, provider, endpoint, client)
}

func fetchNodeQuality(ctx context.Context, provider, endpoint string, client *http.Client) NodeQualityProbe {
	failure := func(reason string) NodeQualityProbe {
		status := "failed"
		if ctx.Err() != nil {
			status, reason = "timeout", "timeout"
		}
		return NodeQualityProbe{Provider: provider, Status: status, Reason: reason}
	}
	start := time.Now()
	var ttfb int64
	ctx = httptrace.WithClientTrace(ctx, &httptrace.ClientTrace{
		GotFirstResponseByte: func() { ttfb = time.Since(start).Milliseconds() },
	})
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return failure("request-failed")
	}
	request.Header.Set("User-Agent", "QuanClash-NodeQuality/1")
	response, err := client.Do(request)
	if err != nil {
		// Only stable categories cross IPC; network errors may contain credentials.
		return failure("request-failed")
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		// The status code is not sensitive and tells a misconfigured URL
		// (404) apart from a rejected client (403) or a server fault (5xx).
		return failure("http-status-" + strconv.Itoa(response.StatusCode))
	}
	if response.ContentLength > nodeQualityBodyLimit {
		return failure("response-too-large")
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, nodeQualityBodyLimit+1))
	if err != nil {
		return failure("request-failed")
	}
	if len(body) > nodeQualityBodyLimit {
		return failure("response-too-large")
	}
	probe, err := parseNodeQualityBody(provider, body)
	if err != nil {
		return failure("invalid-response")
	}
	if ctx.Err() != nil {
		return failure("timeout")
	}
	if provider == "cloudflare" {
		probe.TTFBMs = &ttfb
	}
	return probe
}

func parseNodeQualityBody(provider string, body []byte) (NodeQualityProbe, error) {
	probe := NodeQualityProbe{Provider: provider, Status: "ok"}
	if provider == "custom" {
		return parseCustomQualityBody(probe, body)
	} else if provider == "cloudflare" {
		fields := map[string]string{}
		for _, line := range strings.Split(string(body), "\n") {
			key, value, ok := strings.Cut(strings.TrimSpace(line), "=")
			if ok && (key == "ip" || key == "colo" || key == "loc") {
				if _, duplicate := fields[key]; duplicate {
					return NodeQualityProbe{}, errors.New("duplicate trace field")
				}
				fields[key] = value
			}
		}
		probe.EgressIP, probe.Colo, probe.Country = fields["ip"], fields["colo"], fields["loc"]
		if !nodeQualityCode(probe.Colo, 3) || !nodeQualityCode(probe.Country, 2) {
			return NodeQualityProbe{}, errors.New("invalid trace code")
		}
	} else if provider == "ippure" {
		// Public beta fields: https://ippure.com/en/MyIP-Info-API .
		// Missing risk/type remains unknown; false residential is not 'datacenter'.
		var info struct {
			IP            string `json:"ip"`
			FraudScore    *int   `json:"fraudScore"`
			IsResidential *bool  `json:"isResidential"`
		}
		if err := json.Unmarshal(body, &info); err != nil {
			return NodeQualityProbe{}, errors.New("invalid IP quality data")
		}
		if info.FraudScore != nil && (*info.FraudScore < 0 || *info.FraudScore > 100) {
			return NodeQualityProbe{}, errors.New("invalid risk score")
		}
		probe.EgressIP, probe.RiskScore, probe.IsResidential = info.IP, info.FraudScore, info.IsResidential
	} else {
		return NodeQualityProbe{}, errors.New("unsupported provider")
	}
	ip, err := netip.ParseAddr(probe.EgressIP)
	if err != nil || ip.Zone() != "" || ip.IsUnspecified() || ip.IsMulticast() {
		return NodeQualityProbe{}, errors.New("invalid egress IP")
	}
	probe.EgressIP = ip.Unmap().String()
	if provider == "ippure" && ip.Is6() && !ip.Is4In6() {
		// IPv6 scoring semantics are unverified. A beta default zero is not a verdict.
		probe.RiskScore = nil
	}
	return probe, nil
}

// parseCustomQualityBody accepts the common shapes of third-party IP
// reputation JSON. Only the fields it understands are used; unknown keys are
// ignored so one endpoint can serve several services.
func parseCustomQualityBody(probe NodeQualityProbe, body []byte) (NodeQualityProbe, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(body, &fields); err != nil || fields == nil {
		return NodeQualityProbe{}, errors.New("invalid custom quality data")
	}
	probe.EgressIP = customStringField(fields, "ip", "ipAddress", "ip_address", "query")
	if residential, ok := customBoolField(fields, "isResidential", "is_residential", "residential"); ok {
		probe.IsResidential = &residential
	} else if datacenter, ok := customBoolField(fields, "isDatacenter", "is_datacenter"); ok {
		residential := !datacenter
		probe.IsResidential = &residential
	}
	// Risk-style fields already match QuanClash's scale; trust/reputation is
	// its inverse. Both are normalized to "higher is worse", and the worse of
	// the two wins: a good reputation must not hide a high abuse ratio, and a
	// low abuse ratio must not hide a poor reputation.
	score, found := customNumberField(fields,
		"riskScore", "risk_score", "fraudScore", "fraud_score", "risk",
		"abuseScore", "abuse_score", "abuserScore", "abuser_score",
		"scamScore", "scam_score")
	trust, trustFound := customNumberField(fields,
		"trustScore", "trust_score", "reputation", "reputationScore",
		"reputation_score", "qualityScore", "quality_score", "trust")
	if trustFound {
		trust = 100 - trust
		if !found || trust > score {
			score, found = trust, true
		}
	}
	if !found {
		score, found = customNumberField(fields, "score")
	}
	if found {
		if score < 0 || score > 100 {
			return NodeQualityProbe{}, errors.New("invalid custom risk score")
		}
		probe.RiskScore = &score
	}
	if probe.RiskScore == nil && probe.EgressIP == "" && probe.IsResidential == nil {
		return NodeQualityProbe{}, errors.New("no usable custom quality fields")
	}
	// A custom service may only return a score. The network probe already
	// established the egress IP, so an absent echo is not a failure here; an
	// echo that is present must still be a real address.
	if probe.EgressIP != "" {
		ip, err := netip.ParseAddr(probe.EgressIP)
		if err != nil || ip.Zone() != "" || ip.IsUnspecified() || ip.IsMulticast() {
			return NodeQualityProbe{}, errors.New("invalid egress IP")
		}
		probe.EgressIP = ip.Unmap().String()
	}
	return probe, nil
}

func customStringField(fields map[string]json.RawMessage, keys ...string) string {
	for _, key := range keys {
		raw, ok := fields[key]
		if !ok {
			continue
		}
		var value string
		if json.Unmarshal(raw, &value) == nil {
			if value = strings.TrimSpace(value); value != "" {
				return value
			}
		}
	}
	return ""
}

func customBoolField(fields map[string]json.RawMessage, keys ...string) (bool, bool) {
	for _, key := range keys {
		raw, ok := fields[key]
		if !ok {
			continue
		}
		var value bool
		if json.Unmarshal(raw, &value) == nil {
			return value, true
		}
	}
	return false, false
}

func customNumberField(fields map[string]json.RawMessage, keys ...string) (int, bool) {
	for _, key := range keys {
		raw, ok := fields[key]
		if !ok {
			continue
		}
		var value float64
		if err := json.Unmarshal(raw, &value); err != nil {
			// Some services quote the value, e.g. "0.0234 (Elevated)".
			var text string
			if json.Unmarshal(raw, &text) != nil {
				continue
			}
			parts := strings.Fields(text)
			if len(parts) == 0 {
				continue
			}
			parsed, err := strconv.ParseFloat(parts[0], 64)
			if err != nil {
				continue
			}
			value = parsed
		}
		// Ratios in (0,1] are scaled to the 0-100 scale used elsewhere.
		if value > 0 && value <= 1 {
			value *= 100
		}
		return int(math.Round(value)), true
	}
	return 0, false
}

func nodeQualityCode(value string, length int) bool {
	if len(value) != length {
		return false
	}
	for _, char := range value {
		if char < 'A' || char > 'Z' {
			return false
		}
	}
	return true
}
