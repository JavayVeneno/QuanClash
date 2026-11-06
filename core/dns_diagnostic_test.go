package main

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/config"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/dns"
	"github.com/metacubex/mihomo/hub/executor"
)

func TestDNSDiagnosticUnavailableStates(t *testing.T) {
	preserveConfigState(t)
	currentConfig = nil
	if result := handleGetDNSDiagnostic(); result.Status != "not-configured" || len(result.Routes) != 0 {
		t.Fatalf("unexpected initial diagnostic: %+v", result)
	}
	currentConfig = &config.Config{DNS: &config.DNS{Enable: false, NameServer: []dns.NameServer{{Net: "system"}}}}
	if result := handleGetDNSDiagnostic(); result.Status != "disabled" || len(result.Routes) != 0 {
		t.Fatalf("disabled DNS produced active routes: %+v", result)
	}
	isInit = false
	if result := handleGetDNSDiagnostic(); result.Status != "inactive" || len(result.Routes) != 0 {
		t.Fatalf("inactive core produced active routes: %+v", result)
	}
}

func TestDNSDiagnosticParsedRolesAndRedaction(t *testing.T) {
	preserveConfigState(t)
	cfg, err := executor.ParseWithBytes([]byte(`
dns:
  enable: true
  respect-rules: true
  nameserver: ['https://user:password@dns.example/private-token?secret=yes#eth-test']
  fallback: [tls://8.8.8.8]
  default-nameserver: [9.9.9.9]
  proxy-server-nameserver: [tls://9.9.9.9]
  proxy-server-nameserver-policy:
    '+.secret-node.example': [system://]
  direct-nameserver: [https://1.1.1.1/dns-query#DIRECT]
  direct-nameserver-follow-policy: true
  nameserver-policy:
    '+.private.example': ['system://#eth-test']
    '+.other-private.example': [rcode://name_error]
  fallback-filter:
    geoip: false
`))
	if err != nil {
		t.Fatal(err)
	}
	currentConfig = cfg
	report := handleGetDNSDiagnostic()
	if report.Status != "ready" || report.Source != "active-config" || report.SchemaVersion != 1 || !report.DirectFollowPolicy {
		t.Fatalf("unexpected report metadata: %+v", report)
	}
	wantPaths := []string{"interface", "rules", "system", "synthetic", "direct", "direct", "system", "direct"}
	wantRoles := []string{"nameserver", "fallback", "nameserver-policy", "nameserver-policy", "default-nameserver", "proxy-server-nameserver", "proxy-server-nameserver-policy", "direct-nameserver"}
	if len(report.Routes) != len(wantPaths) {
		t.Fatalf("unexpected route count: %+v", report.Routes)
	}
	for i, route := range report.Routes {
		if route.Path != wantPaths[i] || route.Role != wantRoles[i] {
			t.Errorf("route %d: got %+v, want %s/%s", i, route, wantRoles[i], wantPaths[i])
		}
	}
	if *report.Routes[2].PolicyIndex != 0 || *report.Routes[3].PolicyIndex != 1 {
		t.Fatal("policy indexes lost ordering")
	}
	if report.Routes[0].Endpoint != "dns.example:443" || report.Routes[2].Target != "" {
		t.Fatalf("incorrect endpoint redaction or system routing: %+v", report.Routes)
	}
	encoded, err := json.Marshal(report)
	if err != nil {
		t.Fatal(err)
	}
	for _, secret := range []string{"password", "private-token", "secret=yes", "private.example", "secret-node"} {
		if strings.Contains(string(encoded), secret) {
			t.Errorf("report exposed %s: %s", secret, encoded)
		}
	}
	for _, warning := range []string{"configuration-only-not-a-leak-test", "host-dns-path-present", "rules-may-select-direct", "direct-bootstrap-path-present", "direct-query-path-present"} {
		if !containsWarning(report, warning) {
			t.Errorf("missing warning %s", warning)
		}
	}
	if report.ProxyBootstrap != "dedicated" || report.DirectQueries != "dedicated" {
		t.Fatal("dedicated resolver roles were not reported")
	}
}

func TestDNSDiagnosticPathClassification(t *testing.T) {
	proxies := map[string]C.Proxy{
		"DIRECT": adapter.NewProxy(outbound.NewDirect()),
		"REJECT": adapter.NewProxy(outbound.NewReject()),
	}
	for _, test := range []struct {
		name string
		ns   dns.NameServer
		path string
	}{
		{"plain UDP", dns.NameServer{Addr: "1.1.1.1:53"}, "direct"},
		{"rules", dns.NameServer{Net: "tls", ProxyName: "RULES"}, "rules"},
		{"direct fragment", dns.NameServer{ProxyName: "DIRECT"}, "direct"},
		{"reject", dns.NameServer{ProxyName: "REJECT"}, "blocked"},
		{"interface fragment", dns.NameServer{ProxyName: "eth0"}, "interface"},
		{"system ignores fragment", dns.NameServer{Net: "system", ProxyName: "RULES"}, "system"},
		{"DHCP ignores fragment", dns.NameServer{Net: "dhcp", ProxyName: "DIRECT"}, "dhcp"},
		{"overlay", dns.NameServer{Net: "tailscale", Addr: "tailnet", ProxyName: "RULES"}, "overlay"},
		{"synthetic", dns.NameServer{Net: "rcode", Addr: "name_error"}, "synthetic"},
		{"adapter precedence", dns.NameServer{ProxyAdapter: outbound.NewDirect(), ProxyName: "RULES"}, "direct"},
		{"unsupported transport", dns.NameServer{Net: "future"}, "unknown"},
	} {
		t.Run(test.name, func(t *testing.T) {
			if path, _ := dnsConfiguredPath(test.ns, proxies); path != test.path {
				t.Fatalf("got %s, want %s", path, test.path)
			}
		})
	}
}

func TestDNSDiagnosticProxyAndInheritance(t *testing.T) {
	preserveConfigState(t)
	cfg, err := executor.ParseWithBytes([]byte(`
proxies:
  - name: proxy-test
    type: socks5
    server: 127.0.0.1
    port: 1080
proxy-groups:
  - name: group-test
    type: select
    proxies: [DIRECT, proxy-test]
dns:
  enable: true
  nameserver: ['https://1.1.1.1/dns-query#group-test']
  fallback-filter:
    geoip: false
`))
	if err != nil {
		t.Fatal(err)
	}
	report := buildDNSDiagnostic(cfg)
	if report.Routes[0].Path != "proxy" || report.Routes[0].Target != "group-test" || !containsWarning(report, "configured-proxy-path-not-verified") {
		t.Fatalf("group routing incorrectly declared verified: %+v", report)
	}
	if report.ProxyBootstrap != "inherits-main" || report.DirectQueries != "inherits-main" {
		t.Fatal("implicit resolver inheritance hidden")
	}
	if got := dnsTransport(dns.NameServer{Net: "https", Addr: "http://dns.example/dns-query"}); got != "http" {
		t.Fatal("plain HTTP was mislabeled HTTPS")
	}
}

func TestDNSDiagnosticPreservesActiveSnapshotOnRejectedReload(t *testing.T) {
	preserveConfigState(t)
	currentConfig = &config.Config{DNS: &config.DNS{Enable: true, NameServer: []dns.NameServer{{Net: "system"}}}}
	before, _ := json.Marshal(handleGetDNSDiagnostic())
	if err := applyConfig(defaultSetupParams()); err == nil {
		t.Fatal("missing config was accepted")
	}
	after, _ := json.Marshal(handleGetDNSDiagnostic())
	if string(before) != string(after) {
		t.Fatal("diagnostic used rejected disk config instead of active policy")
	}
}

func containsWarning(report DNSDiagnostic, warning string) bool {
	for _, value := range report.Warnings {
		if value == warning {
			return true
		}
	}
	return false
}
