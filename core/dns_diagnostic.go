package main

import (
	"net"
	"net/url"

	"github.com/metacubex/mihomo/config"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/dns"
)

type DNSDiagnostic struct {
	SchemaVersion      int                  `json:"schemaVersion"`
	Source             string               `json:"source"`
	Status             string               `json:"status"`
	ProxyBootstrap     string               `json:"proxyBootstrap"`
	DirectQueries      string               `json:"directQueries"`
	DirectFollowPolicy bool                 `json:"directFollowPolicy"`
	Routes             []DNSRouteDiagnostic `json:"routes"`
	Warnings           []string             `json:"warnings"`
}

type DNSRouteDiagnostic struct {
	Role        string `json:"role"`
	PolicyIndex *int   `json:"policyIndex,omitempty"`
	ServerIndex int    `json:"serverIndex"`
	Endpoint    string `json:"endpoint"`
	Transport   string `json:"transport"`
	Path        string `json:"path"`
	Target      string `json:"target,omitempty"`
}

func handleGetDNSDiagnostic() DNSDiagnostic {
	runLock.Lock()
	defer runLock.Unlock()
	if !isInit {
		return newDNSDiagnostic("inactive")
	}
	return buildDNSDiagnostic(currentConfig)
}

func newDNSDiagnostic(status string) DNSDiagnostic {
	return DNSDiagnostic{
		SchemaVersion: 1,
		Source:        "active-config",
		Status:        status,
		Routes:        []DNSRouteDiagnostic{},
		Warnings:      []string{"configuration-only-not-a-leak-test"},
	}
}

// Inspect only the parsed active config. No DNS query, process lookup or
// forwarding hook is used; a configured proxy group may still select DIRECT.
func buildDNSDiagnostic(cfg *config.Config) DNSDiagnostic {
	result := newDNSDiagnostic("not-configured")
	if cfg == nil || cfg.DNS == nil {
		return result
	}
	d := cfg.DNS
	if !d.Enable {
		result.Status = "disabled"
		result.Warnings = append(result.Warnings, "core-dns-disabled")
		return result
	}
	result.Status = "ready"
	result.DirectFollowPolicy = d.DirectFollowPolicy
	result.ProxyBootstrap = "dedicated"
	if len(d.ProxyServerNameserver) == 0 {
		result.ProxyBootstrap = "inherits-main"
	}
	result.DirectQueries = "dedicated"
	if len(d.DirectNameServer) == 0 {
		result.DirectQueries = "inherits-main"
	}
	seenWarnings := make(map[string]bool)
	warn := func(code string) {
		if !seenWarnings[code] {
			seenWarnings[code] = true
			result.Warnings = append(result.Warnings, code)
		}
	}
	add := func(role string, policyIndex *int, servers []dns.NameServer) {
		for index, server := range servers {
			path, target := dnsConfiguredPath(server, cfg.Proxies)
			result.Routes = append(result.Routes, DNSRouteDiagnostic{
				Role: role, PolicyIndex: policyIndex, ServerIndex: index,
				Endpoint: dnsSafeEndpoint(server), Transport: dnsTransport(server),
				Path: path, Target: target,
			})
			switch path {
			case "system", "dhcp":
				warn("host-dns-path-present")
			case "direct", "interface":
				if role == "default-nameserver" || role == "proxy-server-nameserver" || role == "proxy-server-nameserver-policy" {
					warn("direct-bootstrap-path-present")
				} else {
					warn("direct-query-path-present")
				}
			case "rules":
				warn("rules-may-select-direct")
			case "proxy", "overlay":
				warn("configured-proxy-path-not-verified")
			case "unknown":
				warn("unknown-dns-path")
			}
		}
	}
	add("nameserver", nil, d.NameServer)
	add("fallback", nil, d.Fallback)
	for index, policy := range d.NameServerPolicy {
		// Policy indexes preserve ordering without exposing queried domain patterns.
		policyIndex := index
		add("nameserver-policy", &policyIndex, policy.NameServers)
	}
	add("default-nameserver", nil, d.DefaultNameserver)
	add("proxy-server-nameserver", nil, d.ProxyServerNameserver)
	for index, policy := range d.ProxyServerPolicy {
		policyIndex := index
		add("proxy-server-nameserver-policy", &policyIndex, policy.NameServers)
	}
	add("direct-nameserver", nil, d.DirectNameServer)
	return result
}

func dnsConfiguredPath(ns dns.NameServer, proxies map[string]C.Proxy) (string, string) {
	// These clients ignore ProxyName and bypass the ordinary DNS dialer.
	switch ns.Net {
	case "system", "dhcp":
		return ns.Net, ""
	case "tailscale", "easytier":
		return "overlay", ns.Addr
	case "rcode":
		return "synthetic", ""
	case "", "tcp", "tls", "https", "quic":
	default:
		return "unknown", ""
	}
	adapter := ns.ProxyAdapter
	if adapter == nil {
		if ns.ProxyName == "" {
			return "direct", ""
		}
		if ns.ProxyName == dns.RespectRules {
			return "rules", ""
		}
		proxy := proxies[ns.ProxyName]
		if proxy == nil {
			// Mihomo interprets a name absent from its proxy map as an interface.
			return "interface", ns.ProxyName
		}
		adapter = proxy
	}
	switch adapter.Type() {
	case C.Direct:
		return "direct", adapter.Name()
	case C.Reject, C.RejectDrop:
		return "blocked", adapter.Name()
	case C.Pass, C.PassRule, C.Rematch, C.Compatible:
		return "unknown", adapter.Name()
	default:
		return "proxy", adapter.Name()
	}
}

func dnsTransport(ns dns.NameServer) string {
	if ns.Net == "" {
		return "udp"
	}
	if ns.Net == "https" {
		if u, err := url.Parse(ns.Addr); err == nil && u.Scheme == "http" {
			return "http"
		}
	}
	return ns.Net
}

func dnsSafeEndpoint(ns dns.NameServer) string {
	switch ns.Net {
	case "system", "dhcp", "tailscale", "easytier", "rcode":
		return ""
	case "https":
		u, err := url.Parse(ns.Addr)
		if err != nil {
			return ""
		}
		// Strip URL userinfo, path, query and fragment: any can contain a token.
		return u.Host
	case "", "tcp", "tls", "quic":
		if host, port, err := net.SplitHostPort(ns.Addr); err == nil {
			return net.JoinHostPort(host, port)
		}
	}
	return ""
}
