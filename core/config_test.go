package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/hub/executor"
)

func preserveConfigState(t *testing.T) {
	t.Helper()
	home, active, testURL, initialized := constant.Path.HomeDir(), currentConfig, constant.DefaultTestURL, isInit
	t.Cleanup(func() {
		constant.SetHomeDir(home)
		currentConfig = active
		constant.DefaultTestURL = testURL
		isInit = initialized
	})
	constant.SetHomeDir(t.TempDir())
	constant.DefaultTestURL = "https://active.example/test"
	isInit = true
}

func TestApplyInvalidConfigPreservesActivePolicy(t *testing.T) {
	for _, test := range []struct {
		name    string
		content string
	}{
		{name: "missing file"},
		{name: "invalid YAML", content: "dns: ["},
		{name: "invalid DNS", content: "dns:\n  enable: true\n  nameserver: []\n"},
	} {
		t.Run(test.name, func(t *testing.T) {
			preserveConfigState(t)
			active := &config.Config{DNS: &config.DNS{Enable: true}}
			currentConfig = active
			if test.content != "" {
				if err := os.WriteFile(filepath.Join(constant.Path.HomeDir(), "config.yaml"), []byte(test.content), 0600); err != nil {
					t.Fatal(err)
				}
			}
			if err := applyConfig(&SetupParams{TestURL: "https://new.example/test"}); err == nil {
				t.Fatal("invalid config was accepted")
			}
			if currentConfig != active || constant.DefaultTestURL != "https://active.example/test" {
				t.Fatal("invalid config replaced the active policy or test URL")
			}
		})
	}
}

func TestFirstInvalidConfigDoesNotInstallDefaults(t *testing.T) {
	preserveConfigState(t)
	currentConfig = nil
	if err := applyConfig(defaultSetupParams()); err == nil {
		t.Fatal("missing config was accepted")
	}
	if currentConfig != nil {
		t.Fatal("defaults were installed after a failed first setup")
	}
}

func TestInvalidSetupParamsDoNotReloadConfig(t *testing.T) {
	preserveConfigState(t)
	active := &config.Config{DNS: &config.DNS{Enable: true}}
	currentConfig = active
	if result := handleSetupConfig([]byte(`{"test-url":`)); result == "" {
		t.Fatal("invalid setup params were accepted")
	}
	if currentConfig != active || constant.DefaultTestURL != "https://active.example/test" {
		t.Fatal("invalid setup params reloaded the config")
	}
}

func TestDNSRulesRoutingAndBootstrapAreSeparate(t *testing.T) {
	preserveConfigState(t)
	cfg, err := executor.ParseWithBytes([]byte(`
dns:
  enable: true
  enhanced-mode: normal
  respect-rules: true
  nameserver: [https://1.1.1.1/dns-query]
  fallback: [tls://8.8.8.8]
  default-nameserver: [9.9.9.9]
  proxy-server-nameserver: [tls://9.9.9.9]
  nameserver-policy:
    '+.example.com': [https://1.1.1.1/dns-query]
  fallback-filter:
    geoip: false
`))
	if err != nil {
		t.Fatal(err)
	}
	if cfg.DNS.NameServer[0].ProxyName != "RULES" || cfg.DNS.Fallback[0].ProxyName != "RULES" || cfg.DNS.NameServerPolicy[0].NameServers[0].ProxyName != "RULES" {
		t.Fatal("nameservers or policy do not follow rules")
	}
	if cfg.DNS.ProxyServerNameserver[0].ProxyName != "" || cfg.DNS.DefaultNameserver[0].ProxyName != "" {
		t.Fatal("bootstrap resolver unexpectedly follows rules")
	}
}

func TestPinnedDNSIPv6AndEscapedTargetParsing(t *testing.T) {
	preserveConfigState(t)
	cfg, err := executor.ParseWithBytes([]byte(`
proxies:
  - {name: node, type: socks5, server: 127.0.0.1, port: 1080}
proxy-groups:
  - {name: 'DNS Group', type: select, proxies: [node]}
dns:
  enable: true
  enhanced-mode: normal
  respect-rules: false
  nameserver: ['tls://[2606:4700:4700::1111]#DNS%20Group&h3=true']
  fallback: ['https://1.1.1.1/dns-query#DNS%20Group']
  nameserver-policy:
    '+.example.com': ['tcp://[2001:4860:4860::8888]#DNS%20Group']
  direct-nameserver: ['udp://9.9.9.9#DNS%20Group']
  default-nameserver: ['2001:4860:4860::8888']
  proxy-server-nameserver: ['tls://[2606:4700:4700::1111]']
  fallback-filter:
    geoip: false
rules: ['MATCH,DIRECT']
`))
	if err != nil {
		t.Fatal(err)
	}
	d := cfg.DNS
	for _, target := range []string{
		d.NameServer[0].ProxyName, d.Fallback[0].ProxyName,
		d.NameServerPolicy[0].NameServers[0].ProxyName, d.DirectNameServer[0].ProxyName,
	} {
		if target != "DNS Group" {
			t.Fatalf("pinned DNS target was lost: %q", target)
		}
	}
	if d.NameServer[0].Params["h3"] != "true" {
		t.Fatal("DNS transport parameter was lost")
	}
	if d.DefaultNameserver[0].ProxyName != "" || d.ProxyServerNameserver[0].ProxyName != "" {
		t.Fatal("bootstrap unexpectedly uses a proxy")
	}
}

func TestDNSRulesRoutingRequiresProxyBootstrap(t *testing.T) {
	preserveConfigState(t)
	_, err := executor.ParseWithBytes([]byte(`
dns:
  enable: true
  respect-rules: true
  nameserver: [https://1.1.1.1/dns-query]
  proxy-server-nameserver: []
`))
	if err == nil {
		t.Fatal("rules-routed DNS without proxy bootstrap was accepted")
	}
}
