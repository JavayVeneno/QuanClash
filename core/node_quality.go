package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptrace"
	"net/netip"
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
	ProxyName string   `json:"proxy-name"`
	Providers []string `json:"providers"`
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
	if request.ProxyName == "" || len(request.ProxyName) > 1024 || len(request.Providers) == 0 || len(request.Providers) > 2 {
		return request, errors.New("invalid node quality request")
	}
	seen := map[string]bool{}
	for _, provider := range request.Providers {
		if (provider != "cloudflare" && provider != "ippure") || seen[provider] {
			return request, errors.New("invalid node quality provider")
		}
		seen[provider] = true
	}
	return request, nil
}

func newNodeQualityResult(request NodeQualityRequest) NodeQualityResult {
	return NodeQualityResult{
		SchemaVersion: 1, Source: "selected-proxy", ProxyName: request.ProxyName,
		SampledAt: time.Now().UTC().Format(time.RFC3339Nano),
		Network:   NodeQualityProbe{Provider: "cloudflare", Status: "not-requested"},
		Quality:   NodeQualityProbe{Provider: "ippure", Status: "not-requested"},
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
	for _, provider := range request.Providers {
		probe := probeNodeQuality(context.Background(), provider, dial)
		if provider == "cloudflare" {
			result.Network = probe
		} else {
			result.Quality = probe
		}
	}
	return result
}

type nodeQualityDial func(context.Context, *C.Metadata) (net.Conn, error)

func nodeQualityEndpoint(provider string) (string, string) {
	switch provider {
	case "cloudflare":
		return "www.cloudflare.com", "/cdn-cgi/trace"
	case "ippure":
		return "my.ippure.com", "/v1/info"
	default:
		return "", ""
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

func probeNodeQuality(parent context.Context, provider string, dial nodeQualityDial) NodeQualityProbe {
	host, path := nodeQualityEndpoint(provider)
	if host == "" {
		return NodeQualityProbe{Provider: provider, Status: "unavailable", Reason: "unsupported-provider"}
	}
	transport := nodeQualityTransport(host, dial)
	defer transport.CloseIdleConnections()
	client := &http.Client{
		Transport:     transport,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	ctx, cancel := context.WithTimeout(parent, nodeQualityProbeTimeout)
	defer cancel()
	return fetchNodeQuality(ctx, provider, "https://"+host+path, client)
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
		return failure("http-status")
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
	if provider == "cloudflare" {
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
