//go:build windows && !cgo

package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"testing"
	"time"

	"github.com/Microsoft/go-winio"
	D "github.com/miekg/dns"
)

// Opt-in: uses only a child core, a private named pipe and loopback endpoints.
// It never changes the application's profile, system proxy, DNS or TUN routes.
func TestDesktopCoreSmoke(t *testing.T) {
	corePath := os.Getenv("QUANCLASH_CORE_SMOKE")
	if corePath == "" {
		t.Skip("set QUANCLASH_CORE_SMOKE to the freshly built Windows core")
	}
	corePath, err := filepath.Abs(corePath)
	if err != nil {
		t.Fatal(err)
	}
	home := t.TempDir()
	origin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "quanclash-smoke")
	}))
	t.Cleanup(origin.Close)

	upstream, err := net.ListenPacket("udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	dnsServer := &D.Server{PacketConn: upstream, Handler: D.HandlerFunc(func(w D.ResponseWriter, query *D.Msg) {
		answer := new(D.Msg).SetReply(query)
		for _, question := range query.Question {
			if question.Qtype == D.TypeA {
				answer.Answer = append(answer.Answer, &D.A{
					Hdr: D.RR_Header{Name: question.Name, Rrtype: D.TypeA, Class: D.ClassINET, Ttl: 1},
					A:   net.ParseIP("203.0.113.7"),
				})
			}
		}
		_ = w.WriteMsg(answer)
	})}
	go func() { _ = dnsServer.ActivateAndServe() }()
	t.Cleanup(func() { _ = dnsServer.Shutdown() })

	proxyAddress := unusedSmokeTCPAddress(t)
	dnsAddress := unusedSmokeTCPAddress(t)
	_, proxyPort, _ := net.SplitHostPort(proxyAddress)
	configPath := filepath.Join(home, "config.yaml")
	yaml := fmt.Sprintf(`
mixed-port: %s
allow-lan: false
bind-address: 127.0.0.1
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
tun:
  enable: false
dns:
  enable: true
  listen: %s
  enhanced-mode: normal
  nameserver: [%s]
  default-nameserver: [%s]
  fallback-filter:
    geoip: false
rules: ['MATCH,DIRECT']
`, proxyPort, dnsAddress, upstream.LocalAddr(), upstream.LocalAddr())
	if err := os.WriteFile(configPath, []byte(yaml), 0600); err != nil {
		t.Fatal(err)
	}

	pipeName := `\\.\pipe\quanclash-smoke-` + filepath.Base(home)
	listener, err := winio.ListenPipe(pipeName, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = listener.Close() })
	logFile, err := os.Create(filepath.Join(home, "core.log"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = logFile.Close() })
	cmd := exec.Command(corePath, pipeName)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Stdout, cmd.Stderr = logFile, logFile
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	exited := make(chan error, 1)
	go func() { exited <- cmd.Wait() }()
	t.Cleanup(func() {
		_ = cmd.Process.Kill()
		select {
		case <-exited:
		case <-time.After(5 * time.Second):
			t.Error("child core failed to exit")
		}
	})
	accepted := make(chan net.Conn, 1)
	go func() {
		connection, err := listener.Accept()
		if err == nil {
			accepted <- connection
		}
	}()
	var ipc net.Conn
	select {
	case ipc = <-accepted:
	case <-time.After(10 * time.Second):
		t.Fatal("child core did not connect to its private named pipe")
	}
	t.Cleanup(func() { _ = ipc.Close() })
	// Drain events continuously like the real client: synchronous notifications
	// can otherwise fill the pipe and block the request tracker during forwarding.
	responses := make(chan ActionResult, 1)
	readErrors := make(chan error, 1)
	go func() {
		for {
			payload, err := readFrame(ipc)
			if err != nil {
				readErrors <- err
				return
			}
			var result ActionResult
			if err := json.Unmarshal(payload, &result); err != nil {
				readErrors <- err
				return
			}
			if result.Id != "" {
				responses <- result
			}
		}
	}()
	sequence := 0
	invoke := func(method Method, data any) any {
		t.Helper()
		sequence++
		id := fmt.Sprintf("smoke-%d", sequence)
		payload, err := json.Marshal(Action{Id: id, Method: method, Data: data})
		if err != nil {
			t.Fatal(err)
		}
		if err := ipc.SetWriteDeadline(time.Now().Add(10 * time.Second)); err != nil {
			t.Fatal(err)
		}
		if err := writeFrame(ipc, payload); err != nil {
			t.Fatal(err)
		}
		select {
		case result := <-responses:
			if result.Id != id || result.Method != method {
				t.Fatalf("unexpected response to %s: %+v", id, result)
			}
			if result.Code != 0 {
				t.Fatalf("%s returned an IPC error: %v", method, result.Data)
			}
			return result.Data
		case err := <-readErrors:
			t.Fatalf("%s response: %v", method, err)
		case <-time.After(10 * time.Second):
			t.Fatalf("%s response timed out", method)
		}
		return nil
	}
	initData, _ := json.Marshal(InitParams{HomeDir: home, Version: 1})
	if invoke(initClashMethod, string(initData)) != true {
		t.Fatal("core initialization failed")
	}
	params, _ := json.Marshal(SetupParams{SelectedMap: map[string]string{}, TestURL: origin.URL})
	if result := invoke(setupConfigMethod, string(params)); result != "" {
		t.Fatalf("valid setup failed: %v", result)
	}
	diagnostic := invoke(getDNSDiagnosticMethod, nil).(map[string]any)
	if diagnostic["status"] != "ready" || diagnostic["source"] != "active-config" {
		t.Fatalf("unexpected active diagnostic: %v", diagnostic)
	}
	activeDiagnostic, _ := json.Marshal(diagnostic)
	checkDiagnostic := func() {
		t.Helper()
		current, _ := json.Marshal(invoke(getDNSDiagnosticMethod, nil))
		if string(current) != string(activeDiagnostic) {
			t.Fatal("rejected reload changed the active DNS diagnostic")
		}
	}
	if invoke(startListenerMethod, nil) != true {
		t.Fatal("listeners did not start")
	}
	proxyURL, _ := url.Parse("http://" + proxyAddress)
	transport := &http.Transport{Proxy: http.ProxyURL(proxyURL)}
	t.Cleanup(transport.CloseIdleConnections)
	client := &http.Client{Transport: transport, Timeout: 5 * time.Second}
	checkForwarding := func(label string) {
		t.Helper()
		response, err := client.Get(origin.URL + "/" + label)
		if err != nil {
			t.Fatalf("%s HTTP forwarding: %v", label, err)
		}
		body, err := io.ReadAll(response.Body)
		_ = response.Body.Close()
		if err != nil || response.StatusCode != http.StatusOK || string(body) != "quanclash-smoke" {
			t.Fatalf("%s HTTP response: status=%d body=%q err=%v", label, response.StatusCode, body, err)
		}
		// Use a fresh name on both transports, so a cached answer cannot hide a policy change.
		for _, network := range []string{"udp", "tcp"} {
			query := new(D.Msg).SetQuestion(label+"-"+network+".invalid.", D.TypeA)
			answer, _, err := (&D.Client{Net: network, Timeout: 3 * time.Second}).Exchange(query, dnsAddress)
			if err != nil {
				t.Fatalf("%s %s DNS: %v", label, network, err)
			}
			if answer.Rcode != D.RcodeSuccess || len(answer.Answer) != 1 || answer.Answer[0].(*D.A).A.String() != "203.0.113.7" {
				t.Fatalf("%s %s DNS: unexpected response %v", label, network, answer)
			}
		}
	}
	checkForwarding("valid")
	for _, invalid := range []string{"", "dns: [", "dns:\n  enable: true\n  nameserver: []\n"} {
		if err := os.WriteFile(configPath, []byte(invalid), 0600); err != nil {
			t.Fatal(err)
		}
		if result := invoke(setupConfigMethod, string(params)); result == "" {
			t.Fatal("invalid config was accepted")
		}
		checkDiagnostic()
		transport.CloseIdleConnections()
		checkForwarding(fmt.Sprintf("rejected-%d", sequence))
	}
	if result := invoke(setupConfigMethod, `{"test-url":`); result == "" {
		t.Fatal("invalid setup JSON was accepted")
	}
	checkDiagnostic()
	transport.CloseIdleConnections()
	checkForwarding("rejected-json")
	if invoke(stopListenerMethod, nil) != true || invoke(shutdownMethod, nil) != true || invoke(getIsInitMethod, nil) != false {
		t.Fatal("core lifecycle shutdown failed")
	}
	if diagnostic := invoke(getDNSDiagnosticMethod, nil).(map[string]any); diagnostic["status"] != "inactive" {
		t.Fatal("shutdown core still reported active DNS routes")
	}
	t.Log("named-pipe IPC, lifecycle, HTTP forwarding and UDP/TCP DNS survive rejected reloads")
}

func unusedSmokeTCPAddress(t *testing.T) string {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	return listener.Addr().String()
}
