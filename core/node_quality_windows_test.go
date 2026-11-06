//go:build windows && !cgo

package main

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"testing"
	"time"
)

// Opt-in IPC test. A loopback SOCKS server refuses all connections and cannot
// forward packets. No public endpoint, system proxy/DNS, TUN or helper is used.
func TestDesktopNodeQualitySmoke(t *testing.T) {
	corePath := os.Getenv("QUANCLASH_NODE_QUALITY_SMOKE")
	if corePath == "" {
		t.Skip("set QUANCLASH_NODE_QUALITY_SMOKE to a matching private child core")
	}
	corePath, err := filepath.Abs(corePath)
	if err != nil {
		t.Fatal(err)
	}
	server, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	destinations := make(chan string, 4)
	serverErrors := make(chan error, 4)
	done := make(chan struct{})
	var workers sync.WaitGroup
	go func() {
		defer close(done)
		for {
			connection, err := server.Accept()
			if err != nil {
				return
			}
			workers.Add(1)
			go func() {
				defer workers.Done()
				defer connection.Close()
				_ = connection.SetDeadline(time.Now().Add(3 * time.Second))
				destination, err := nodeQualityRefuseSOCKS(connection)
				if err != nil {
					serverErrors <- err
					return
				}
				destinations <- destination
			}()
		}
	}()
	t.Cleanup(func() { _ = server.Close(); <-done; workers.Wait() })
	_, port, _ := net.SplitHostPort(server.Addr().String())
	yaml := fmt.Sprintf(`
mixed-port: 0
allow-lan: false
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
tun: {enable: false}
dns: {enable: false}
proxies:
  - {name: node, type: socks5, server: 127.0.0.1, port: %s}
proxy-groups:
  - {name: group, type: select, proxies: [node]}
rules: ['MATCH,REJECT']
`, port)
	ipc, _ := startBaselineCore(t, corePath, yaml)
	query := func(name string, providers []string) NodeQualityResult {
		t.Helper()
		request, _ := json.Marshal(NodeQualityRequest{ProxyName: name, Providers: providers})
		value := ipc.invoke(t, testNodeQualityMethod, string(request))
		data, err := json.Marshal(value)
		if err != nil {
			t.Fatal(err)
		}
		var result NodeQualityResult
		if err := json.Unmarshal(data, &result); err != nil {
			t.Fatal(err)
		}
		if result.SchemaVersion != 1 || result.Source != "selected-proxy" || result.ProxyName != name {
			t.Fatalf("wrong IPC schema or identity: %+v", result)
		}
		return result
	}
	cloudflare := []string{"cloudflare"}
	missing := query("missing", cloudflare)
	if missing.Network.Status != "unavailable" || missing.Network.Reason != "proxy-not-found" || missing.Quality.Status != "not-requested" {
		t.Fatal(missing)
	}
	group := query("group", cloudflare)
	if group.Network.Reason != "group-not-supported" {
		t.Fatal(group)
	}
	if _, err := ipc.call(testNodeQualityMethod, `{"proxy-name":"node","providers":["cloudflare"],"url":"https://untrusted"}`); err == nil {
		t.Fatal("IPC accepted untrusted probe endpoint")
	}
	first := query("node", cloudflare)
	if first.Network.Status != "failed" || first.Network.Reason != "request-failed" || first.Quality.Status != "not-requested" {
		t.Fatal(first)
	}
	second := query("node", []string{"cloudflare", "ippure"})
	if second.Network.Status != "failed" || second.Quality.Status != "failed" || second.Quality.RiskScore != nil || second.Quality.EgressIP != "" {
		t.Fatal(second)
	}
	for _, expected := range []string{"www.cloudflare.com:443", "www.cloudflare.com:443", "my.ippure.com:443"} {
		select {
		case destination := <-destinations:
			if destination != expected {
				t.Fatalf("destination=%q want=%q", destination, expected)
			}
		case err := <-serverErrors:
			t.Fatal(err)
		case <-time.After(time.Second):
			t.Fatal("selected SOCKS node did not receive its fixed probe target")
		}
	}
	if ipc.invoke(t, shutdownMethod, nil) != true {
		t.Fatal("shutdown failed")
	}
	inactive := query("node", cloudflare)
	if inactive.Network.Reason != "inactive" {
		t.Fatal(inactive)
	}
	t.Log("private IPC schema/opt-in, concrete adapter dialing, fixed destinations, refusal errors and inactive state passed; no remote probe")
}

func nodeQualityRefuseSOCKS(connection net.Conn) (string, error) {
	header := make([]byte, 2)
	if _, err := io.ReadFull(connection, header); err != nil {
		return "", err
	}
	if header[0] != 5 || header[1] == 0 {
		return "", fmt.Errorf("invalid SOCKS greeting")
	}
	methods := make([]byte, int(header[1]))
	if _, err := io.ReadFull(connection, methods); err != nil {
		return "", err
	}
	if _, err := connection.Write([]byte{5, 0}); err != nil {
		return "", err
	}
	request := make([]byte, 5)
	if _, err := io.ReadFull(connection, request); err != nil {
		return "", err
	}
	if request[0] != 5 || request[1] != 1 || request[3] != 3 || request[4] == 0 {
		return "", fmt.Errorf("probe did not use SOCKS domain CONNECT")
	}
	address := make([]byte, int(request[4])+2)
	if _, err := io.ReadFull(connection, address); err != nil {
		return "", err
	}
	destination := net.JoinHostPort(string(address[:len(address)-2]), strconv.Itoa(int(binary.BigEndian.Uint16(address[len(address)-2:]))))
	_, err := connection.Write([]byte{5, 1, 0, 1, 127, 0, 0, 1, 0, 0})
	return destination, err
}
