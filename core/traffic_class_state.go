package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"sync/atomic"
	"unicode/utf8"
)

var (
	errTrafficClassConflict = errors.New("traffic class revision conflict")
	errTrafficClassInactive = errors.New("traffic class config inactive")
)

type trafficClassSnapshot struct {
	ready    bool
	revision string
	classes  *trafficClasses
}

// Writers serialize publication; future classification readers can load one
// immutable snapshot without locking. Resets invalidate pending CAS requests.
type trafficClassState struct {
	writeMu sync.Mutex
	current atomic.Pointer[trafficClassSnapshot]
}

var trafficClassPolicy trafficClassState

type trafficClassSummary struct {
	ID       string `json:"id"`
	Priority int32  `json:"priority"`
}

type trafficClassDiagnostic struct {
	SchemaVersion int                   `json:"schemaVersion"`
	Status        string                `json:"status"`
	Revision      string                `json:"revision"`
	Enforcing     bool                  `json:"enforcing"`
	Classes       []trafficClassSummary `json:"classes"`
}

func newTrafficClassRevision() (string, error) {
	var token [16]byte
	if _, err := rand.Read(token[:]); err != nil {
		return "", fmt.Errorf("traffic class revision unavailable")
	}
	return hex.EncodeToString(token[:]), nil
}

func validTrafficClassRevision(revision string) bool {
	decoded, err := hex.DecodeString(revision)
	return err == nil && len(decoded) == 16 && revision == strings.ToLower(revision)
}

func (state *trafficClassState) reset(ready bool) {
	state.writeMu.Lock()
	defer state.writeMu.Unlock()
	// Token creation is lazy: invalidation cannot fail even if entropy fails.
	state.current.Store(&trafficClassSnapshot{ready: ready})
}

func (state *trafficClassState) invalidate() {
	state.writeMu.Lock()
	defer state.writeMu.Unlock()
	current := state.current.Load()
	state.current.Store(&trafficClassSnapshot{ready: current != nil && current.ready})
}

func (state *trafficClassState) snapshot() (*trafficClassSnapshot, error) {
	current := state.current.Load()
	if current == nil || !current.ready || current.revision != "" {
		return current, nil
	}
	state.writeMu.Lock()
	defer state.writeMu.Unlock()
	current = state.current.Load()
	if current == nil || !current.ready || current.revision != "" {
		return current, nil
	}
	revision, err := newTrafficClassRevision()
	if err != nil {
		return nil, err
	}
	current = &trafficClassSnapshot{ready: true, revision: revision}
	state.current.Store(current)
	return current, nil
}

func (state *trafficClassState) replace(expected string, classes *trafficClasses) (*trafficClassSnapshot, error) {
	if !validTrafficClassRevision(expected) || classes == nil {
		return nil, fmt.Errorf("invalid traffic class replacement")
	}
	state.writeMu.Lock()
	defer state.writeMu.Unlock()
	current := state.current.Load()
	if current == nil || !current.ready {
		return nil, errTrafficClassInactive
	}
	if current.revision != expected {
		return nil, errTrafficClassConflict
	}
	revision, err := newTrafficClassRevision()
	if err != nil {
		return nil, err
	}
	next := &trafficClassSnapshot{ready: true, revision: revision, classes: classes}
	state.current.Store(next)
	return next, nil
}

func summarizeTrafficClasses(snapshot *trafficClassSnapshot) trafficClassDiagnostic {
	result := trafficClassDiagnostic{SchemaVersion: 1, Status: "inactive", Classes: []trafficClassSummary{}}
	if snapshot == nil || !snapshot.ready {
		return result
	}
	result.Status, result.Revision = "prepared", snapshot.revision
	if snapshot.classes != nil {
		for _, class := range snapshot.classes.classes {
			result.Classes = append(result.Classes, trafficClassSummary{ID: class.id, Priority: class.priority})
		}
	}
	// No process/path/package selectors or misleading enforcement claim leave
	// the diagnostic boundary. The data-plane hook is not enabled yet.
	return result
}

func handleGetTrafficClassState() (trafficClassDiagnostic, error) {
	runLock.Lock()
	defer runLock.Unlock()
	current, err := trafficClassPolicy.snapshot()
	if err != nil {
		return trafficClassDiagnostic{}, err
	}
	return summarizeTrafficClasses(current), nil
}

func handleSetTrafficClasses(data any) (trafficClassDiagnostic, error) {
	text, ok := data.(string)
	if !ok || len(text) > 1024*1024 || !utf8.ValidString(text) {
		return trafficClassDiagnostic{}, fmt.Errorf("invalid traffic class request")
	}
	fields, err := trafficClassObject([]byte(text), "schemaVersion", "expectedRevision", "config")
	if err != nil {
		return trafficClassDiagnostic{}, err
	}
	var schema int
	var revision string
	if json.Unmarshal(fields["schemaVersion"], &schema) != nil || schema != 1 ||
		json.Unmarshal(fields["expectedRevision"], &revision) != nil || !validTrafficClassRevision(revision) {
		return trafficClassDiagnostic{}, fmt.Errorf("invalid traffic class request")
	}
	classes, err := parseTrafficClasses(fields["config"])
	if err != nil {
		return trafficClassDiagnostic{}, err
	}
	// Parse before locking lifecycle work, but compare again at publication:
	// a reset while parsing must reject this request, not restore an old policy.
	runLock.Lock()
	defer runLock.Unlock()
	snapshot, err := trafficClassPolicy.replace(revision, classes)
	if err != nil {
		return trafficClassDiagnostic{}, err
	}
	return summarizeTrafficClasses(snapshot), nil
}
