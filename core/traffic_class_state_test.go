package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"sync"
	"testing"
)

func classSet(t *testing.T, id string) *trafficClasses {
	t.Helper()
	classes, err := parseTrafficClasses(trafficClassFixture(map[string]any{
		"id": id, "priority": 5, "match": map[string]any{"networks": []string{"tcp"}},
	}))
	if err != nil {
		t.Fatal(err)
	}
	return classes
}

func classRequest(revision string, config []byte) string {
	data, _ := json.Marshal(map[string]any{
		"schemaVersion": 1, "expectedRevision": revision, "config": json.RawMessage(config),
	})
	return string(data)
}

func isolateClassPolicy(t *testing.T) {
	t.Helper()
	previous := trafficClassPolicy.current.Load()
	trafficClassPolicy.reset(false)
	t.Cleanup(func() { trafficClassPolicy.current.Store(previous) })
}

func TestTrafficClassStateAtomicReplacementAndReset(t *testing.T) {
	var state trafficClassState
	current, err := state.snapshot()
	if err != nil || summarizeTrafficClasses(current).Status != "inactive" {
		t.Fatal("uninitialized state is not inactive")
	}
	state.reset(true)
	first, err := state.snapshot()
	if err != nil || !validTrafficClassRevision(first.revision) {
		t.Fatal("missing initial revision")
	}
	second, err := state.replace(first.revision, classSet(t, "first"))
	if err != nil || second.revision == first.revision {
		t.Fatal("replacement did not rotate revision")
	}
	if _, err := state.replace(first.revision, classSet(t, "stale")); !errors.Is(err, errTrafficClassConflict) {
		t.Fatal("stale request was not rejected")
	}
	if state.current.Load() != second || first.classes != nil {
		t.Fatal("stale write changed state or mutated previous snapshot")
	}
	state.reset(true)
	third, err := state.snapshot()
	if err != nil || third.revision == second.revision || !third.classes.empty() {
		t.Fatal("reset retained policy or reused revision")
	}
	if _, err := state.replace(second.revision, classSet(t, "old-epoch")); !errors.Is(err, errTrafficClassConflict) {
		t.Fatal("lifecycle reset admitted obsolete write")
	}
	state.reset(false)
	if _, err := state.replace(third.revision, classSet(t, "inactive")); !errors.Is(err, errTrafficClassInactive) {
		t.Fatal("inactive state accepted configuration")
	}
	if id, _, ok := second.classes.classify(trafficInput()); !ok || id != "first" {
		t.Fatal("captured immutable snapshot was mutated")
	}
}

func TestTrafficClassInvalidationCannotEnableUnpreparedConfig(t *testing.T) {
	var state trafficClassState
	for _, initialized := range []bool{false, true} {
		if initialized {
			state.reset(false)
		}
		state.invalidate()
		current, err := state.snapshot()
		if err != nil || current.ready || current.revision != "" {
			t.Fatal("listener/update invalidation enabled an unprepared config")
		}
	}
	state.reset(true)
	previous, _ := state.snapshot()
	state.invalidate()
	current, err := state.snapshot()
	if err != nil || !current.ready || current.revision == previous.revision {
		t.Fatal("prepared config lost readiness or reused revision")
	}
}

func TestTrafficClassConcurrentCompareAndSwapHasOneWinner(t *testing.T) {
	var state trafficClassState
	state.reset(true)
	first, err := state.snapshot()
	if err != nil {
		t.Fatal(err)
	}
	const clients = 24
	classes := make([]*trafficClasses, clients)
	for i := range classes {
		classes[i] = classSet(t, fmt.Sprintf("class-%d", i))
	}
	results := make(chan error, clients)
	var wait sync.WaitGroup
	start := make(chan struct{})
	for _, next := range classes {
		wait.Add(1)
		go func(next *trafficClasses) {
			defer wait.Done()
			<-start
			_, err := state.replace(first.revision, next)
			results <- err
		}(next)
	}
	close(start)
	wait.Wait()
	close(results)
	winners := 0
	for err := range results {
		if err == nil {
			winners++
		} else if !errors.Is(err, errTrafficClassConflict) {
			t.Fatal(err)
		}
	}
	if winners != 1 {
		t.Fatalf("got %d winners", winners)
	}
}

func TestTrafficClassReadersSeeCompleteSnapshotsDuringResets(t *testing.T) {
	var state trafficClassState
	a, b := classSet(t, "a"), classSet(t, "b")
	var wait sync.WaitGroup
	failures := make(chan error, 4)
	for reader := 0; reader < 4; reader++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			for i := 0; i < 200; i++ {
				snapshot, err := state.snapshot()
				if err != nil {
					failures <- err
					return
				}
				if snapshot == nil || !snapshot.ready || snapshot.classes == nil {
					continue
				}
				id, priority, ok := snapshot.classes.classify(trafficInput())
				if !ok || (id != "a" && id != "b") || priority != 5 || !validTrafficClassRevision(snapshot.revision) {
					failures <- fmt.Errorf("torn snapshot")
					return
				}
			}
		}()
	}
	for i := 0; i < 200; i++ {
		state.reset(true)
		current, err := state.snapshot()
		if err != nil {
			t.Fatal(err)
		}
		classes := a
		if i%2 == 0 {
			classes = b
		}
		if _, err := state.replace(current.revision, classes); err != nil {
			t.Fatal(err)
		}
	}
	wait.Wait()
	close(failures)
	for err := range failures {
		t.Fatal(err)
	}
}

func TestTrafficClassActionsRejectInvalidWritesAndRedactSelectors(t *testing.T) {
	isolateClassPolicy(t)
	trafficClassPolicy.reset(true)
	initial, err := handleGetTrafficClassState()
	if err != nil || initial.Enforcing || initial.Status != "prepared" {
		t.Fatal("invalid initial state")
	}
	config := trafficClassFixture(map[string]any{
		"id": "browser", "priority": -2,
		"match": map[string]any{"processNames": []string{"secret.exe"}},
	})
	accepted, err := handleSetTrafficClasses(classRequest(initial.Revision, config))
	if err != nil || accepted.Revision == initial.Revision || accepted.Enforcing {
		t.Fatal("valid write failed")
	}
	wire, _ := json.Marshal(accepted)
	if strings.Contains(string(wire), "secret") || strings.Contains(string(wire), "processNames") {
		t.Fatal("diagnostic leaked selectors")
	}
	accepted.Classes[0].ID = "mutated"
	for _, bad := range []any{
		nil, true, map[string]any{}, `null`, `{}`,
		classRequest(initial.Revision, config),
		classRequest(strings.Repeat("A", 32), config),
		classRequest(accepted.Revision, []byte(`{"schemaVersion":1,"classes":null}`)),
		`{"schemaVersion":1,"schemaVersion":1,"expectedRevision":"` + accepted.Revision + `","config":` + string(config) + `}`,
	} {
		if _, err := handleSetTrafficClasses(bad); err == nil {
			t.Fatalf("invalid request accepted: %T", bad)
		}
		current, err := handleGetTrafficClassState()
		if err != nil || current.Revision != accepted.Revision || current.Classes[0].ID != "browser" {
			t.Fatal("failed write/mutated response changed accepted policy")
		}
	}
	cleared, err := handleSetTrafficClasses(classRequest(accepted.Revision, trafficClassFixture()))
	if err != nil || len(cleared.Classes) != 0 || cleared.Revision == accepted.Revision {
		t.Fatal("explicit empty replacement did not clear")
	}
}

func TestTrafficClassInvalidConfigReloadPreservesRevision(t *testing.T) {
	preserveConfigState(t)
	isolateClassPolicy(t)
	trafficClassPolicy.reset(true)
	first, _ := trafficClassPolicy.snapshot()
	accepted, err := trafficClassPolicy.replace(first.revision, classSet(t, "active"))
	if err != nil {
		t.Fatal(err)
	}
	// preserveConfigState uses a fresh temp home without config.yaml. Rejection
	// must not invalidate the separate accepted traffic policy.
	if err := applyConfig(defaultSetupParams()); err == nil {
		t.Fatal("missing config accepted")
	}
	if current := trafficClassPolicy.current.Load(); !reflect.DeepEqual(current, accepted) {
		t.Fatal("rejected reload invalidated traffic policy")
	}
}
