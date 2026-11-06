//go:build windows && !cgo

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

// Opt-in, low-volume loopback IPC test. No system proxy/DNS/TUN/helper changes.
func TestDesktopConnectionUpdatesSmoke(t *testing.T) {
	corePath := os.Getenv("QUANCLASH_CONNECTION_UPDATES_SMOKE")
	if corePath == "" {
		t.Skip("set QUANCLASH_CONNECTION_UPDATES_SMOKE to a matching child core")
	}
	corePath, err := filepath.Abs(corePath)
	if err != nil {
		t.Fatal(err)
	}
	ipc, _, proxy, dnsAddress, tcp, udp, _ := experimentChild(t, corePath)
	query := func(cursor string) connectionUpdateResponse {
		t.Helper()
		request, _ := json.Marshal(connectionUpdateRequest{SchemaVersion: 1, Cursor: cursor})
		value := ipc.invoke(t, getConnectionUpdatesMethod, string(request))
		encoded, err := json.Marshal(value)
		if err != nil {
			t.Fatal(err)
		}
		var result connectionUpdateResponse
		if err := json.Unmarshal(encoded, &result); err != nil {
			t.Fatal(err)
		}
		if result.SchemaVersion != 1 {
			t.Fatal("invalid update schema")
		}
		return result
	}
	first := query("")
	if !first.Full || first.Status != "ready" || first.Cursor == "" || len(first.Upserted) != 0 {
		t.Fatalf("empty initial snapshot: %+v", first)
	}
	if _, err := ipc.call(getConnectionUpdatesMethod, `{"schemaVersion":2}`); err == nil {
		t.Fatal("invalid schema was not rejected via IPC")
	}
	empty := query(first.Cursor)
	if empty.Full || empty.BaseCursor != first.Cursor || len(empty.Upserted)+len(empty.Updated)+len(empty.Removed) != 0 {
		t.Fatal("rejected request changed cursor baseline")
	}
	operation := baselineTCPOperation(t, proxy, tcp, false)
	if _, err := operation(); err != nil {
		t.Fatal(err)
	}
	added := query(empty.Cursor)
	if added.Full || len(added.Upserted) != 1 {
		t.Fatalf("TCP addition: %+v", added)
	}
	var tcpInfo struct {
		ID       string `json:"id"`
		Upload   int64  `json:"upload"`
		Download int64  `json:"download"`
	}
	if err := json.Unmarshal(added.Upserted[0], &tcpInfo); err != nil || tcpInfo.Upload < 65536 || tcpInfo.Download < 65536 {
		t.Fatalf("TCP transfer counts: %+v, %v", tcpInfo, err)
	}
	if _, err := operation(); err != nil {
		t.Fatal(err)
	}
	counters := query(added.Cursor)
	if counters.Full || len(counters.Upserted) != 0 || len(counters.Updated) != 1 || counters.Updated[0].Upload <= tcpInfo.Upload {
		t.Fatalf("TCP counter-only delta: %+v", counters)
	}
	if _, err := baselineUDPOperation(t, proxy, udp)(); err != nil {
		t.Fatal(err)
	}
	withUDP := query(counters.Cursor)
	if withUDP.Full || len(withUDP.Upserted) != 1 {
		t.Fatalf("UDP addition: %+v", withUDP)
	}
	if ipc.invoke(t, closeConnectionMethod, tcpInfo.ID) != true {
		t.Fatal("close TCP failed")
	}
	removed := query(withUDP.Cursor)
	if removed.Full || len(removed.Removed) != 1 || removed.Removed[0].ID != tcpInfo.ID || removed.Removed[0].FinalCountersVerified {
		t.Fatalf("TCP removal must disclose final counters unavailable: %+v", removed)
	}
	// Replay an old cursor after a lost response must return a full snapshot.
	resync := query(counters.Cursor)
	if !resync.Full || len(resync.Upserted) != 1 || len(resync.Removed) != 0 {
		t.Fatal("lost cursor did not resynchronize")
	}
	if ipc.invoke(t, resetConnectionsMethod, nil) != true {
		t.Fatal("resolver reset failed")
	}
	// No expiry or policy change is inferred from a resolver reset. Live UDP
	// state remains whatever the manager reports; comparison is snapshot-based.
	current := query(resync.Cursor)
	if current.Full {
		t.Fatal("resolver reset unexpectedly broke the inspection cursor")
	}
	if ipc.invoke(t, stopListenerMethod, nil) != true || ipc.invoke(t, startListenerMethod, nil) != true {
		t.Fatal("listener restart failed")
	}
	restarted := query(current.Cursor)
	if !restarted.Full || restarted.Cursor == current.Cursor {
		t.Fatal("listener restart reused old inspection baseline")
	}
	// Reuse real loopback DNS as a small forwarding check after inspection.
	if _, err := baselineDNSOperation(t, dnsAddress, "udp", "updates-smoke")(); err != nil {
		t.Fatal(fmt.Errorf("DNS after inspection: %w", err))
	}
	if ipc.invoke(t, stopListenerMethod, nil) != true || ipc.invoke(t, shutdownMethod, nil) != true {
		t.Fatal("shutdown failed")
	}
	inactive := query(restarted.Cursor)
	if inactive.Status != "inactive" || !inactive.Full || inactive.Cursor != "" || len(inactive.Upserted) != 0 {
		t.Fatal("shutdown core emitted stale live inspection state")
	}
	t.Log("versioned IPC, counter-only updates, TCP/UDP additions, removals, stale-cursor resync and restart/shutdown passed")
}
