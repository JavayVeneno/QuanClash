package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	C "github.com/metacubex/mihomo/constant"
)

func TestNodeQualityRequest(t *testing.T) {
	for _, data := range []any{nil, map[string]string{}, "", "null", `{}`, `{"proxy-name":"p","providers":[]}`,
		`{"proxy-name":"p","providers":["other"]}`, `{"proxy-name":"p","providers":["ippure","ippure"]}`,
		`{"proxy-name":"p","providers":["ippure"],"url":"https://secret"}`,
		`{"proxy-name":"p","providers":["ippure"]} {}`, strings.Repeat("x", 4097),
		// Custom endpoints must arrive with exactly one provider and vice versa.
		`{"proxy-name":"p","providers":["cloudflare","custom"]}`,
		`{"proxy-name":"p","providers":["cloudflare"],"quality-urls":["https://example.com/a"]}`,
		`{"proxy-name":"p","providers":["cloudflare","custom"],"quality-urls":["http://example.com/a"]}`,
		`{"proxy-name":"p","providers":["cloudflare","custom"],"quality-urls":["https://127.0.0.1/a"]}`,
		`{"proxy-name":"p","providers":["custom","custom"],"quality-urls":["https://example.com/a"]}`} {
		if _, err := parseNodeQualityRequest(data); err == nil {
			t.Fatalf("accepted invalid request: %v", data)
		}
	}
	request, err := parseNodeQualityRequest(`{"proxy-name":"p","providers":["cloudflare","ippure"]}`)
	if err != nil || request.ProxyName != "p" || len(request.Providers) != 2 {
		t.Fatalf("valid request rejected: %+v, %v", request, err)
	}
	custom, err := parseNodeQualityRequest(`{"proxy-name":"p","providers":["cloudflare","custom"],"quality-urls":["https://ip.net.coffee/api/iprisk/{ip}"]}`)
	if err != nil || len(custom.QualityURLs) != 1 {
		t.Fatalf("valid custom request rejected: %+v, %v", custom, err)
	}
}

func TestCustomQualityURL(t *testing.T) {
	for raw, want := range map[string]string{
		"https://ip.net.coffee/api/iprisk/{ip}": "https://ip.net.coffee:443/api/iprisk/quanclash-ip-placeholder",
		"https://example.com":                   "https://example.com:443/",
		"https://example.com/check?ip={ip}":     "https://example.com:443/check?ip=quanclash-ip-placeholder",
		"https://example.com:443/a":             "https://example.com:443/a",
	} {
		got, err := validateCustomQualityURL(raw)
		if err != nil || got != want {
			t.Fatalf("%q => %q, %v; want %q", raw, got, err, want)
		}
	}
	for _, raw := range []string{
		"", "not a url", "http://example.com/a", "ftp://example.com/a",
		"https://example.com:8443/a", "https://localhost/a", "https://127.0.0.1/a",
		"https://10.0.0.1/a", "https://192.168.1.1/a", "https://[::1]/a",
		"https://" + "user" + ":" + "pass" + "@example.com/a", "https://example.com/a#b",
		"https://example.com/../a", "https://{ip}.example.com/a",
		"https://example.com/a b",
	} {
		if _, err := validateCustomQualityURL(raw); err == nil {
			t.Fatalf("accepted invalid endpoint: %q", raw)
		}
	}
}

func TestCustomQualityEndpointSubstitution(t *testing.T) {
	request := NodeQualityRequest{
		ProxyName: "p", Providers: []string{"cloudflare", "custom"},
		QualityURLs: []string{"https://ip.net.coffee/api/iprisk/{ip}"},
	}
	endpoint, err := customQualityEndpoint(request, "203.0.113.9")
	if err != nil || endpoint != "https://ip.net.coffee:443/api/iprisk/203.0.113.9" {
		t.Fatalf("substitution => %q, %v", endpoint, err)
	}
	if _, err := customQualityEndpoint(request, ""); err == nil {
		t.Fatal("missing egress IP did not fail the placeholder")
	}
	static := NodeQualityRequest{
		ProxyName: "p", Providers: []string{"cloudflare", "custom"},
		QualityURLs: []string{"https://example.com/check"},
	}
	if endpoint, err := customQualityEndpoint(static, ""); err != nil || endpoint != "https://example.com:443/check" {
		t.Fatalf("static endpoint => %q, %v", endpoint, err)
	}
}

// Observed payload of https://ip.net.coffee/api/iprisk/<ip> on 2026-11-16.
// The quoted abuse ratio is zero while the reputation is merely good, so the
// score must come from the reputation rather than reading as a perfect zero.
func TestCustomQualityIpNetCoffee(t *testing.T) {
	body := `{"ip": "111.238.48.199", "cidr": "111.238.48.192/27",
		"is_datacenter": true, "isResidential": false, "isBroadcast": null,
		"is_vpn": false, "is_proxy": false, "is_tor": false,
		"is_crawler": false, "is_abuser": false, "is_mobile": false,
		"company_type": "business", "company_name": "Tokyo Online CO.,Ltd",
		"abuser_score": "0 (Very Low)", "asn": 2516, "asnum": 2516,
		"asOrganization": "KDDI CORPORATION", "country": "Japan",
		"countryCode": "jp", "trust_score": 88, "rpi_status": "invalid"}`
	probe, err := parseNodeQualityBody("custom", []byte(body))
	if err != nil {
		t.Fatal(err)
	}
	if probe.RiskScore == nil || *probe.RiskScore != 12 {
		t.Fatalf("risk score => %+v", probe.RiskScore)
	}
	if probe.EgressIP != "111.238.48.199" {
		t.Fatalf("egress IP => %q", probe.EgressIP)
	}
	if probe.IsResidential == nil || *probe.IsResidential {
		t.Fatalf("residential => %+v", probe.IsResidential)
	}
}

func TestNodeQualityParsers(t *testing.T) {
	for _, tc := range []struct {
		name, provider, body string
		valid                bool
	}{
		{"trace", "cloudflare", "ip=203.0.113.1\ncolo=HKG\nloc=HK\n", true},
		{"IPv6", "cloudflare", "ip=2001:db8::1\ncolo=SJC\nloc=US\n", true},
		{"trace missing IP", "cloudflare", "colo=HKG\nloc=HK", false},
		{"trace IP duplicate", "cloudflare", "ip=203.0.113.1\nip=203.0.113.2\ncolo=HKG\nloc=HK", false},
		{"trace malicious code", "cloudflare", "ip=203.0.113.1\ncolo=secret-token\nloc=HK", false},
		{"trace scoped IP", "cloudflare", "ip=fe80::1%eth0\ncolo=HKG\nloc=HK", false},
		{"quality", "ippure", `{"ip":"203.0.113.1","fraudScore":75,"isResidential":false,"future":"ignored"}`, true},
		{"quality zero", "ippure", `{"ip":"203.0.113.1","fraudScore":0,"isResidential":true}`, true},
		{"quality IPv6", "ippure", `{"ip":"2001:db8::1","fraudScore":0}`, true},
		{"quality missing score", "ippure", `{"ip":"203.0.113.1"}`, true},
		{"quality null score", "ippure", `{"ip":"203.0.113.1","fraudScore":null}`, true},
		{"quality type", "ippure", `{"ip":"203.0.113.1","fraudScore":"75"}`, false},
		{"quality negative", "ippure", `{"ip":"203.0.113.1","fraudScore":-1}`, false},
		{"quality range", "ippure", `{"ip":"203.0.113.1","fraudScore":101}`, false},
		{"quality fractional", "ippure", `{"ip":"203.0.113.1","fraudScore":0.5}`, false},
		{"quality missing IP", "ippure", `{"fraudScore":75}`, false},
		{"quality html", "ippure", `<html>secret-token</html>`, false},
		{"quality trailing", "ippure", `{"ip":"203.0.113.1"} {}`, false},
		{"custom risk", "custom", `{"ip":"203.0.113.1","risk_score":40,"is_residential":true}`, true},
		{"custom trust", "custom", `{"ip":"203.0.113.1","trust_score":80}`, true},
		{"custom camel trust", "custom", `{"trustScore":20}`, true},
		{"custom quoted ratio", "custom", `{"ip":"203.0.113.1","abuser_score":"0.0234 (Elevated)"}`, true},
		{"custom trust with quiet abuse", "custom", `{"ip":"203.0.113.1","trust_score":88,"abuser_score":"0 (Very Low)"}`, true},
		{"custom abuse worse than trust", "custom", `{"ip":"203.0.113.1","trust_score":90,"abuse_score":0.8}`, true},
		{"custom datacenter", "custom", `{"ip":"203.0.113.1","is_datacenter":true}`, true},
		{"custom score only", "custom", `{"score":55}`, true},
		{"custom range", "custom", `{"risk_score":150}`, false},
		{"custom empty", "custom", `{}`, false},
		{"custom html", "custom", `<html>secret-token</html>`, false},
		{"custom bad IP", "custom", `{"ip":"not-an-ip","risk_score":10}`, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			result, err := parseNodeQualityBody(tc.provider, []byte(tc.body))
			if (err == nil) != tc.valid {
				t.Fatalf("result=%+v err=%v", result, err)
			}
			if tc.valid && result.Status != "ok" {
				t.Fatal(result)
			}
			if tc.name == "quality missing score" && result.RiskScore != nil {
				t.Fatal("missing score became zero")
			}
			if tc.name == "quality IPv6" && result.RiskScore != nil {
				t.Fatal("unverified IPv6 score was exposed")
			}
			if tc.name == "quality zero" && (result.RiskScore == nil || *result.RiskScore != 0) {
				t.Fatal("real zero lost")
			}
			switch tc.name {
			case "custom trust":
				if result.RiskScore == nil || *result.RiskScore != 20 {
					t.Fatalf("trust polarity not inverted: %+v", result.RiskScore)
				}
			case "custom camel trust":
				if result.RiskScore == nil || *result.RiskScore != 80 {
					t.Fatalf("camel trust polarity not inverted: %+v", result.RiskScore)
				}
			case "custom quoted ratio":
				if result.RiskScore == nil || *result.RiskScore != 2 {
					t.Fatalf("quoted ratio not normalized: %+v", result.RiskScore)
				}
			case "custom trust with quiet abuse":
				// A zero abuse ratio must not mask a mediocre reputation.
				if result.RiskScore == nil || *result.RiskScore != 12 {
					t.Fatalf("trust not used over quiet abuse: %+v", result.RiskScore)
				}
			case "custom abuse worse than trust":
				// A good reputation must not mask a high abuse ratio.
				if result.RiskScore == nil || *result.RiskScore != 80 {
					t.Fatalf("abuse not used over trust: %+v", result.RiskScore)
				}
			case "custom datacenter":
				if result.IsResidential == nil || *result.IsResidential {
					t.Fatalf("datacenter not inverted: %+v", result.IsResidential)
				}
			case "custom risk":
				if result.RiskScore == nil || *result.RiskScore != 40 ||
					result.IsResidential == nil || !*result.IsResidential {
					t.Fatalf("custom risk fields lost: %+v", result)
				}
			}
		})
	}
}

// Exercise production HTTPS transport while dialing only an isolated TLS server.
func nodeQualityTestClient(t *testing.T, handler http.Handler) (*http.Client, *atomic.Int32) {
	t.Helper()
	server := httptest.NewUnstartedServer(handler)
	server.TLS = &tls.Config{Certificates: []tls.Certificate{}}
	server.StartTLS()
	t.Cleanup(server.Close)
	var calls atomic.Int32
	transport := nodeQualityTransport("example.com", func(ctx context.Context, metadata *C.Metadata) (net.Conn, error) {
		calls.Add(1)
		if metadata.Host != "example.com" || metadata.DstPort != 443 || metadata.NetWork != C.TCP || metadata.DstIP.IsValid() {
			t.Errorf("wrong selected-adapter metadata: %+v", metadata)
		}
		return (&net.Dialer{}).DialContext(ctx, "tcp", server.Listener.Addr().String())
	})
	roots := x509.NewCertPool()
	roots.AddCert(server.Certificate())
	transport.TLSClientConfig = &tls.Config{RootCAs: roots}
	t.Cleanup(transport.CloseIdleConnections)
	return &http.Client{
		Transport:     transport,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}, &calls
}

func TestNodeQualityHTTPS(t *testing.T) {
	client, calls := nodeQualityTestClient(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Host != "example.com" || r.URL.Path != "/v1/info" || r.Method != http.MethodGet {
			t.Errorf("unexpected request: %v", r)
		}
		io.WriteString(w, `{"ip":"203.0.113.1","fraudScore":75,"isResidential":false}`)
	}))
	result := fetchNodeQuality(context.Background(), "ippure", "https://example.com/v1/info", client)
	if result.Status != "ok" || result.RiskScore == nil || *result.RiskScore != 75 || calls.Load() != 1 {
		t.Fatal(result, calls.Load())
	}
	transport := client.Transport.(*http.Transport)
	if transport.Proxy != nil {
		t.Fatal("inherited system/environment proxy")
	}
	if _, err := transport.DialContext(context.Background(), "tcp", "other.example:443"); err == nil || calls.Load() != 1 {
		t.Fatal("unexpected destination was dialed")
	}
}

func TestNodeQualityHTTPFailures(t *testing.T) {
	for _, tc := range []struct {
		name, reason string
		handler      http.HandlerFunc
	}{
		{"redirect", "http-status-302", func(w http.ResponseWriter, r *http.Request) {
			http.Redirect(w, r, "https://secret.example/token", http.StatusFound)
		}},
		{"rate limit", "http-status-429", func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(429)
			io.WriteString(w, "secret-token")
		}},
		{"bad data", "invalid-response", func(w http.ResponseWriter, _ *http.Request) { io.WriteString(w, "secret-token") }},
		{"declared size", "response-too-large", func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Length", "262145")
			w.WriteHeader(200)
		}},
		{"stream size", "response-too-large", func(w http.ResponseWriter, _ *http.Request) {
			w.(http.Flusher).Flush()
			io.WriteString(w, strings.Repeat("x", nodeQualityBodyLimit+1))
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client, calls := nodeQualityTestClient(t, tc.handler)
			result := fetchNodeQuality(context.Background(), "ippure", "https://example.com/v1/info", client)
			data, _ := json.Marshal(result)
			if result.Status != "failed" || !strings.HasPrefix(result.Reason, tc.reason) || result.RiskScore != nil || calls.Load() != 1 || strings.Contains(string(data), "secret") {
				t.Fatal(string(data), calls.Load())
			}
		})
	}
}

func TestNodeQualityTimeout(t *testing.T) {
	client, _ := nodeQualityTestClient(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.(http.Flusher).Flush()
		<-r.Context().Done()
	}))
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	result := fetchNodeQuality(ctx, "ippure", "https://example.com/v1/info", client)
	if result.Status != "timeout" || result.Reason != "timeout" || result.RiskScore != nil {
		t.Fatal(result)
	}
}

type nodeQualityErrorTransport struct{}

func (nodeQualityErrorTransport) RoundTrip(*http.Request) (*http.Response, error) {
	return nil, errors.New("secret-auth-token")
}

func TestNodeQualityRedactsErrors(t *testing.T) {
	result := fetchNodeQuality(context.Background(), "ippure", "https://example.com/v1/info", &http.Client{Transport: nodeQualityErrorTransport{}})
	data, _ := json.Marshal(result)
	if result.Reason != "request-failed" || strings.Contains(string(data), "secret") {
		t.Fatal(string(data))
	}
}

func TestNodeQualityInactive(t *testing.T) {
	// No initialization or outbound request is needed for this path.
	result, err := handleTestNodeQuality(`{"proxy-name":"missing","providers":["cloudflare"]}`)
	if err != nil || result.Network.Status != "unavailable" || result.Quality.Status != "not-requested" {
		t.Fatal(result, err)
	}
	if result.Network.Reason != "inactive" && result.Network.Reason != "proxy-not-found" {
		t.Fatal(result)
	}
}

type nodeQualityStubProxy struct {
	C.Proxy
	kind  C.AdapterType
	dials int
}

func (p *nodeQualityStubProxy) Type() C.AdapterType { return p.kind }

func (p *nodeQualityStubProxy) DialContext(context.Context, *C.Metadata) (C.Conn, error) {
	p.dials++
	return nil, errors.New("secret-token")
}

func TestNodeQualityAdmissionAndIndependentFailures(t *testing.T) {
	request := NodeQualityRequest{ProxyName: "node", Providers: []string{"cloudflare", "ippure"}}
	slots := make(chan struct{}, 2)
	for _, kind := range []C.AdapterType{C.Selector, C.URLTest, C.Fallback, C.LoadBalance, C.Relay, C.Pass, C.Rematch} {
		proxy := &nodeQualityStubProxy{kind: kind}
		result := testNodeQualityThroughProxy(request, proxy, slots)
		if result.Network.Reason != "group-not-supported" || proxy.dials != 0 {
			t.Fatal(result, proxy.dials)
		}
	}
	proxy := &nodeQualityStubProxy{kind: C.Shadowsocks}
	slots <- struct{}{}
	slots <- struct{}{}
	busy := testNodeQualityThroughProxy(request, proxy, slots)
	if busy.Network.Reason != "busy" || busy.Quality.Reason != "busy" || proxy.dials != 0 {
		t.Fatal(busy, proxy.dials)
	}
	<-slots
	<-slots
	result := testNodeQualityThroughProxy(request, proxy, slots)
	if result.Network.Status != "failed" || result.Quality.Status != "failed" || proxy.dials != 2 || len(slots) != 0 {
		t.Fatal(result, proxy.dials, len(slots))
	}
	if result.Network.RiskScore != nil || result.Quality.RiskScore != nil {
		t.Fatal("failures fabricated scores")
	}
}
