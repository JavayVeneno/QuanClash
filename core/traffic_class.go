package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"path/filepath"
	"runtime"
	"strings"
	"unicode/utf8"

	C "github.com/metacubex/mihomo/constant"
)

const (
	trafficClassSchemaVersion = 1
	trafficClassMaxClasses    = 256
	trafficClassMaxValues     = 128
	trafficClassMaxIDLength   = 64
	trafficClassMaxTextLength = 1024
)

type trafficClassDefinition struct {
	ID       string            `json:"id"`
	Priority int32             `json:"priority"`
	Match    trafficClassMatch `json:"match"`
}

type trafficClassMatch struct {
	ProcessNames []string `json:"processNames"`
	ProcessPaths []string `json:"processPaths"`
	UIDs         []uint32 `json:"uids"`
	Packages     []string `json:"packages"`
	Networks     []string `json:"networks"`
}

type compiledTrafficClass struct {
	id           string
	priority     int32
	processNames map[string]struct{}
	processPaths map[string]struct{}
	uids         map[uint32]struct{}
	packages     map[string]struct{}
	networks     map[string]struct{}
}

// trafficClasses is immutable after parsing. Classification never allocates
// timers, queues or per-connection state.
type trafficClasses struct {
	classes []compiledTrafficClass
}

// Metadata has no UID-validity flag and Process can contain either an executable
// or a package. The caller must supply resolved identity, never infer UID 0.
type trafficClassInput struct {
	Metadata    *C.Metadata
	UIDKnown    bool
	PackageName string
}

func validateTrafficClassText(value, field string) error {
	if value == "" || len(value) > trafficClassMaxTextLength || value != strings.TrimSpace(value) {
		return fmt.Errorf("invalid traffic class %s", field)
	}
	for _, char := range value {
		if char < 32 || char == 127 {
			return fmt.Errorf("invalid traffic class %s", field)
		}
	}
	return nil
}

func validateTrafficClassID(value string) error {
	if len(value) == 0 || len(value) > trafficClassMaxIDLength {
		return fmt.Errorf("invalid traffic class id")
	}
	for _, char := range value {
		if (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') ||
			(char >= '0' && char <= '9') || char == '.' || char == '_' || char == '-' {
			continue
		}
		return fmt.Errorf("invalid traffic class id")
	}
	return nil
}

func compileClassStrings(values []string, field string, normalize func(string) (string, error)) (map[string]struct{}, error) {
	if len(values) == 0 {
		return nil, nil
	}
	if len(values) > trafficClassMaxValues {
		return nil, fmt.Errorf("too many traffic class %s", field)
	}
	result := make(map[string]struct{}, len(values))
	for _, value := range values {
		if err := validateTrafficClassText(value, field); err != nil {
			return nil, err
		}
		value, err := normalize(value)
		if err != nil {
			return nil, err
		}
		if _, exists := result[value]; exists {
			return nil, fmt.Errorf("duplicate traffic class %s", field)
		}
		result[value] = struct{}{}
	}
	return result, nil
}

func normalizeClassLiteral(value string) (string, error) {
	return value, nil
}

func normalizeClassProcessName(value string) (string, error) {
	if runtime.GOOS == "windows" {
		return strings.ToLower(value), nil
	}
	return value, nil
}

func normalizeClassProcessPath(value string) (string, error) {
	if !filepath.IsAbs(value) {
		return "", fmt.Errorf("traffic class path must be absolute")
	}
	path := filepath.Clean(value)
	if runtime.GOOS == "windows" {
		path = strings.ToLower(path)
	}
	return path, nil
}

func normalizeClassNetwork(value string) (string, error) {
	switch network := strings.ToLower(value); network {
	case "tcp", "udp":
		return network, nil
	default:
		return "", fmt.Errorf("invalid traffic class network")
	}
}

func compileTrafficClass(definition trafficClassDefinition) (compiledTrafficClass, error) {
	if err := validateTrafficClassID(definition.ID); err != nil {
		return compiledTrafficClass{}, err
	}
	processNames, err := compileClassStrings(definition.Match.ProcessNames, "process name", normalizeClassProcessName)
	if err != nil {
		return compiledTrafficClass{}, err
	}
	processPaths, err := compileClassStrings(definition.Match.ProcessPaths, "process path", normalizeClassProcessPath)
	if err != nil {
		return compiledTrafficClass{}, err
	}
	packages, err := compileClassStrings(definition.Match.Packages, "package", normalizeClassLiteral)
	if err != nil {
		return compiledTrafficClass{}, err
	}
	networks, err := compileClassStrings(definition.Match.Networks, "network", normalizeClassNetwork)
	if err != nil {
		return compiledTrafficClass{}, err
	}
	if len(definition.Match.UIDs) > trafficClassMaxValues {
		return compiledTrafficClass{}, fmt.Errorf("too many traffic class uids")
	}
	uids := make(map[uint32]struct{}, len(definition.Match.UIDs))
	for _, uid := range definition.Match.UIDs {
		if _, exists := uids[uid]; exists {
			return compiledTrafficClass{}, fmt.Errorf("duplicate traffic class uid")
		}
		uids[uid] = struct{}{}
	}
	if len(processNames)+len(processPaths)+len(uids)+len(packages)+len(networks) == 0 {
		return compiledTrafficClass{}, fmt.Errorf("empty traffic class match")
	}
	return compiledTrafficClass{
		id: definition.ID, priority: definition.Priority,
		processNames: processNames, processPaths: processPaths, uids: uids,
		packages: packages, networks: networks,
	}, nil
}

// Exact keys and duplicate/null rejection prevent permissive JSON decoding from
// silently weakening a match dimension. Callers cap the complete document first.
func trafficClassObject(data []byte, allowed ...string) (map[string]json.RawMessage, error) {
	decoder := json.NewDecoder(bytes.NewReader(data))
	start, err := decoder.Token()
	if err != nil || start != json.Delim('{') {
		return nil, fmt.Errorf("invalid traffic class config")
	}
	fields := make(map[string]json.RawMessage)
	for decoder.More() {
		key, err := decoder.Token()
		if err != nil {
			return nil, fmt.Errorf("invalid traffic class key")
		}
		name, ok := key.(string)
		if !ok {
			return nil, fmt.Errorf("invalid traffic class key")
		}
		known := false
		for _, value := range allowed {
			known = known || name == value
		}
		if _, duplicate := fields[name]; !known || duplicate {
			return nil, fmt.Errorf("unknown or duplicate traffic class key")
		}
		var raw json.RawMessage
		if err := decoder.Decode(&raw); err != nil || bytes.Equal(bytes.TrimSpace(raw), []byte("null")) {
			return nil, fmt.Errorf("invalid traffic class value")
		}
		fields[name] = raw
	}
	if _, err := decoder.Token(); err != nil {
		return nil, fmt.Errorf("invalid traffic class config")
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		return nil, fmt.Errorf("trailing traffic class config")
	}
	return fields, nil
}

func parseTrafficClasses(data []byte) (*trafficClasses, error) {
	if len(data) == 0 || len(data) > 1024*1024 || !utf8.Valid(data) {
		return nil, fmt.Errorf("invalid traffic class config size or encoding")
	}
	root, err := trafficClassObject(data, "schemaVersion", "classes")
	if err != nil {
		return nil, err
	}
	var schema int
	if err := json.Unmarshal(root["schemaVersion"], &schema); err != nil || schema != trafficClassSchemaVersion {
		return nil, fmt.Errorf("unsupported traffic class config")
	}
	var definitions []json.RawMessage
	if err := json.Unmarshal(root["classes"], &definitions); err != nil || len(definitions) > trafficClassMaxClasses {
		return nil, fmt.Errorf("invalid traffic class list")
	}
	result := &trafficClasses{classes: make([]compiledTrafficClass, 0, len(definitions))}
	ids := make(map[string]struct{}, len(definitions))
	for _, raw := range definitions {
		fields, err := trafficClassObject(raw, "id", "priority", "match")
		if err != nil {
			return nil, err
		}
		var definition trafficClassDefinition
		if err := json.Unmarshal(fields["id"], &definition.ID); err != nil {
			return nil, fmt.Errorf("invalid traffic class id")
		}
		if raw, exists := fields["priority"]; exists {
			if err := json.Unmarshal(raw, &definition.Priority); err != nil {
				return nil, fmt.Errorf("invalid traffic class priority")
			}
		}
		match, err := trafficClassObject(fields["match"], "processNames", "processPaths", "uids", "packages", "networks")
		if err != nil {
			return nil, err
		}
		for name, raw := range match {
			if name == "uids" {
				var values []json.RawMessage
				if err := json.Unmarshal(raw, &values); err != nil || len(values) == 0 || len(values) > trafficClassMaxValues {
					return nil, fmt.Errorf("invalid traffic class uids")
				}
				for _, value := range values {
					var uid uint32
					if bytes.Equal(bytes.TrimSpace(value), []byte("null")) || json.Unmarshal(value, &uid) != nil {
						return nil, fmt.Errorf("invalid traffic class uid")
					}
					definition.Match.UIDs = append(definition.Match.UIDs, uid)
				}
				continue
			}
			var values []string
			if err := json.Unmarshal(raw, &values); err != nil || len(values) == 0 {
				return nil, fmt.Errorf("invalid traffic class match values")
			}
			switch name {
			case "processNames":
				definition.Match.ProcessNames = values
			case "processPaths":
				definition.Match.ProcessPaths = values
			case "packages":
				definition.Match.Packages = values
			case "networks":
				definition.Match.Networks = values
			}
		}
		if _, exists := ids[definition.ID]; exists {
			return nil, fmt.Errorf("duplicate traffic class id")
		}
		compiled, err := compileTrafficClass(definition)
		if err != nil {
			return nil, err
		}
		ids[definition.ID] = struct{}{}
		result.classes = append(result.classes, compiled)
	}
	return result, nil
}

func (classes *trafficClasses) empty() bool {
	return classes == nil || len(classes.classes) == 0
}

func (class compiledTrafficClass) matches(input trafficClassInput) bool {
	metadata := input.Metadata
	if metadata == nil {
		return false
	}
	if len(class.processNames) > 0 {
		name, _ := normalizeClassProcessName(metadata.Process)
		if _, exists := class.processNames[name]; !exists {
			return false
		}
	}
	if len(class.processPaths) > 0 {
		path, err := normalizeClassProcessPath(metadata.ProcessPath)
		if err != nil {
			return false
		}
		if _, exists := class.processPaths[path]; !exists {
			return false
		}
	}
	if len(class.uids) > 0 {
		if !input.UIDKnown {
			return false
		}
		if _, exists := class.uids[metadata.Uid]; !exists {
			return false
		}
	}
	if len(class.packages) > 0 {
		if _, exists := class.packages[input.PackageName]; !exists {
			return false
		}
	}
	if len(class.networks) > 0 {
		if _, exists := class.networks[strings.ToLower(metadata.NetWork.String())]; !exists {
			return false
		}
	}
	return true
}

// classify returns the first matching class in configuration order. Priority is
// scheduling metadata and never changes match precedence.
func (classes *trafficClasses) classify(input trafficClassInput) (string, int32, bool) {
	if classes == nil {
		return "", 0, false
	}
	for _, class := range classes.classes {
		if class.matches(input) {
			return class.id, class.priority, true
		}
	}
	return "", 0, false
}
