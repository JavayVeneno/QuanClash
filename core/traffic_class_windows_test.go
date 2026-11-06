//go:build windows && !cgo

package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

// Only a private child and loopback fixtures; no app/helper/network managers.
func TestDesktopTrafficClassStateSmoke(t *testing.T) {
	corePath := os.Getenv("QUANCLASH_TRAFFIC_CLASS_SMOKE")
	if corePath == "" {
		t.Skip("set QUANCLASH_TRAFFIC_CLASS_SMOKE to a matching private core")
	}
	corePath, err := filepath.Abs(corePath)
	if err != nil {
		t.Fatal(err)
	}
	ipc, _, proxy, _, tcp, _, _ := experimentChild(t, corePath)
	decode := func(value any) trafficClassDiagnostic {
		t.Helper()
		wire, err := json.Marshal(value)
		if err != nil {
			t.Fatal(err)
		}
		var result trafficClassDiagnostic
		if err := json.Unmarshal(wire, &result); err != nil || result.SchemaVersion != 1 || result.Enforcing {
			t.Fatalf("invalid diagnostic: %+v, %v", result, err)
		}
		return result
	}
	query := func() trafficClassDiagnostic {
		return decode(ipc.invoke(t, getTrafficClassStateMethod, nil))
	}
	config := trafficClassFixture(map[string]any{
		"id": "interactive", "priority": 5, "match": map[string]any{"networks": []string{"tcp"}},
	})
	install := func(revision string) trafficClassDiagnostic {
		return decode(ipc.invoke(t, setTrafficClassesMethod, classRequest(revision, config)))
	}
	first := query()
	if first.Status != "prepared" || !validTrafficClassRevision(first.Revision) || len(first.Classes) != 0 {
		t.Fatal("initial state must be prepared, empty and not enforcing")
	}
	second := install(first.Revision)
	if len(second.Classes) != 1 || second.Classes[0].ID != "interactive" || second.Revision == first.Revision {
		t.Fatal("missing accepted class/revision")
	}
	if _, err := ipc.call(setTrafficClassesMethod, classRequest(first.Revision, config)); err == nil {
		t.Fatal("IPC admitted stale revision")
	}
	if _, err := ipc.call(setTrafficClassesMethod, classRequest(second.Revision, []byte(`{"schemaVersion":1,"classes":null}`))); err == nil {
		t.Fatal("IPC admitted malformed config")
	}
	if current := query(); current.Revision != second.Revision || len(current.Classes) != 1 {
		t.Fatal("rejection changed policy")
	}
	if result := ipc.invoke(t, setupConfigMethod, `{"test-url":`); result == "" {
		t.Fatal("invalid setup accepted")
	}
	if current := query(); current.Revision != second.Revision {
		t.Fatal("rejected setup reset class state")
	}
	// This is still ordinary unshaped forwarding. There is no classification
	// data-path hook and the response must continue to disclose enforcing=false.
	operation := baselineTCPOperation(t, proxy, tcp, false)
	if _, err := operation(); err != nil {
		t.Fatal(err)
	}
	params, _ := json.Marshal(SetupParams{SelectedMap: map[string]string{}, TestURL: "http://127.0.0.1/"})
	for _, action := range []struct {
		method Method
		data   any
	}{
		{setupConfigMethod, string(params)},
		{updateConfigMethod, `{}`},
		{stopListenerMethod, nil},
		{startListenerMethod, nil},
	} {
		previous := query()
		if len(previous.Classes) == 0 {
			previous = install(previous.Revision)
		}
		ipc.invoke(t, action.method, action.data)
		next := query()
		if next.Status != "prepared" || next.Revision == previous.Revision || len(next.Classes) != 0 {
			t.Fatalf("%s did not invalidate policy", action.method)
		}
		if _, err := ipc.call(setTrafficClassesMethod, classRequest(previous.Revision, config)); err == nil {
			t.Fatalf("%s admitted previous epoch", action.method)
		}
	}
	if ipc.invoke(t, shutdownMethod, nil) != true {
		t.Fatal("shutdown failed")
	}
	inactive := query()
	if inactive.Status != "inactive" || inactive.Revision != "" || len(inactive.Classes) != 0 {
		t.Fatal("shutdown retained configuration")
	}
	if _, err := ipc.call(setTrafficClassesMethod, classRequest(second.Revision, config)); err == nil {
		t.Fatal("shutdown accepted policy")
	}
	t.Log("private IPC CAS, redacted prepared state, lifecycle reset and inactive shutdown passed; no QoS hook enabled")
}
