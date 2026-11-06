package main

import (
	"encoding/json"
	"fmt"
	"net/netip"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	C "github.com/metacubex/mihomo/constant"
)

func trafficClassFixture(classes ...map[string]any) []byte {
	if classes == nil {
		classes = []map[string]any{}
	}
	data, err := json.Marshal(map[string]any{
		"schemaVersion": 1,
		"classes":       classes,
	})
	if err != nil {
		panic(err)
	}
	return data
}

func trafficMetadata() *C.Metadata {
	path := `C:\Program Files\Browser\browser.exe`
	if runtime.GOOS != "windows" {
		path = "/opt/Browser/browser"
	}
	return &C.Metadata{
		NetWork:     C.TCP,
		SrcIP:       netip.MustParseAddr("127.0.0.1"),
		SrcPort:     12345,
		DstIP:       netip.MustParseAddr("198.51.100.1"),
		DstPort:     443,
		Process:     "Browser.EXE",
		ProcessPath: path,
		Uid:         42,
	}
}

func trafficInput() trafficClassInput {
	return trafficClassInput{Metadata: trafficMetadata(), UIDKnown: true, PackageName: "com.example.browser"}
}

func TestTrafficClassClassifiesFirstMatchByConfigurationOrder(t *testing.T) {
	classes, err := parseTrafficClasses(trafficClassFixture(
		map[string]any{
			"id": "interactive", "priority": 20,
			"match": map[string]any{
				"processNames": []string{"Browser.EXE"},
			},
		},
		map[string]any{
			"id": "browser-path", "priority": 10,
			"match": map[string]any{
				"processPaths": []string{trafficMetadata().ProcessPath},
				"networks":     []string{"TCP"},
			},
		},
	))
	if err != nil {
		t.Fatal(err)
	}
	id, priority, ok := classes.classify(trafficInput())
	if !ok || id != "interactive" || priority != 20 {
		t.Fatalf("unexpected first match: id=%q priority=%d ok=%t", id, priority, ok)
	}
}

func TestTrafficClassRequiresEveryConfiguredDimension(t *testing.T) {
	classes, err := parseTrafficClasses(trafficClassFixture(
		map[string]any{
			"id": "browser-tcp", "priority": -5,
			"match": map[string]any{
				"processNames": []string{"Browser.EXE"},
				"processPaths": []string{trafficMetadata().ProcessPath},
				"uids":         []uint32{42},
				"packages":     []string{"com.example.browser"},
				"networks":     []string{"tcp"},
			},
		},
	))
	if err != nil {
		t.Fatal(err)
	}
	id, priority, ok := classes.classify(trafficInput())
	if !ok || id != "browser-tcp" || priority != -5 {
		t.Fatalf("unexpected match: id=%q priority=%d ok=%t", id, priority, ok)
	}
	for name, mutate := range map[string]func(*C.Metadata){
		"process": func(metadata *C.Metadata) { metadata.Process = "other.exe" },
		"path":    func(metadata *C.Metadata) { metadata.ProcessPath = `C:\other\browser.exe` },
		"uid":     func(metadata *C.Metadata) { metadata.Uid = 43 },
		"network": func(metadata *C.Metadata) { metadata.NetWork = C.UDP },
	} {
		t.Run(name, func(t *testing.T) {
			metadata := trafficMetadata()
			mutate(metadata)
			input := trafficInput()
			input.Metadata = metadata
			if id, _, ok := classes.classify(input); ok {
				t.Fatalf("unexpected cross-dimension match: %s", id)
			}
		})
	}
	input := trafficInput()
	input.PackageName = "com.other.browser"
	if _, _, ok := classes.classify(input); ok {
		t.Fatal("wrong package matched")
	}
}

func TestTrafficClassProcessNameCaseFoldingMatchesPlatform(t *testing.T) {
	classes, err := parseTrafficClasses(trafficClassFixture(
		map[string]any{
			"id": "browser",
			"match": map[string]any{
				"processNames": []string{"browser.exe"},
			},
		},
	))
	if err != nil {
		t.Fatal(err)
	}
	metadata := trafficMetadata()
	id, _, ok := classes.classify(trafficClassInput{Metadata: metadata})
	if runtime.GOOS == "windows" {
		if !ok || id != "browser" {
			t.Fatalf("Windows process name should be case-insensitive: id=%q ok=%t", id, ok)
		}
		return
	}
	if ok {
		t.Fatalf("non-Windows process name should remain case-sensitive: %s", id)
	}
}

func TestTrafficClassEmptySetAndNilMetadataDoNotMatch(t *testing.T) {
	classes, err := parseTrafficClasses(trafficClassFixture())
	if err != nil || !classes.empty() {
		t.Fatalf("empty config: %+v, %v", classes, err)
	}
	if _, _, ok := classes.classify(trafficInput()); ok {
		t.Fatal("empty set matched")
	}
	var nilClasses *trafficClasses
	if _, _, ok := nilClasses.classify(trafficInput()); ok {
		t.Fatal("nil set matched")
	}
	if _, _, ok := classes.classify(trafficClassInput{}); ok {
		t.Fatal("nil metadata matched")
	}
}

func TestTrafficClassRejectsAmbiguousOrUnboundedConfiguration(t *testing.T) {
	valid := map[string]any{
		"id": "browser", "priority": 0,
		"match": map[string]any{"processNames": []string{"browser.exe"}},
	}
	cases := map[string][]byte{
		"missing root":     []byte(`null`),
		"unknown root":     []byte(`{"schemaVersion":1,"classes":[],"extra":true}`),
		"wrong schema":     []byte(`{"schemaVersion":2,"classes":[]}`),
		"null classes":     []byte(`{"schemaVersion":1,"classes":null}`),
		"trailing json":    []byte(`{"schemaVersion":1,"classes":[]} {}`),
		"oversized config": make([]byte, 1024*1024+1),
		"duplicate id":     trafficClassFixture(valid, valid),
		"empty match":      trafficClassFixture(map[string]any{"id": "empty", "match": map[string]any{}}),
		"unknown match":    trafficClassFixture(map[string]any{"id": "unknown", "match": map[string]any{"hosts": []string{"example.com"}}}),
		"invalid id":       trafficClassFixture(map[string]any{"id": "bad id", "match": map[string]any{"networks": []string{"tcp"}}}),
		"long id":          trafficClassFixture(map[string]any{"id": strings.Repeat("a", trafficClassMaxIDLength+1), "match": map[string]any{"networks": []string{"tcp"}}}),
		"blank name":       trafficClassFixture(map[string]any{"id": "blank", "match": map[string]any{"processNames": []string{" "}}}),
		"padded name":      trafficClassFixture(map[string]any{"id": "padded", "match": map[string]any{"processNames": []string{" browser.exe "}}}),
		"long name":        trafficClassFixture(map[string]any{"id": "long", "match": map[string]any{"processNames": []string{strings.Repeat("a", trafficClassMaxTextLength+1)}}}),
		"duplicate name":   trafficClassFixture(map[string]any{"id": "duplicate", "match": map[string]any{"processNames": []string{"browser.exe", "browser.exe"}}}),
		"invalid network":  trafficClassFixture(map[string]any{"id": "network", "match": map[string]any{"networks": []string{"icmp"}}}),
		"duplicate uid":    trafficClassFixture(map[string]any{"id": "uid", "match": map[string]any{"uids": []uint32{1, 1}}}),
	}
	for name, data := range cases {
		t.Run(name, func(t *testing.T) {
			if classes, err := parseTrafficClasses(data); err == nil {
				t.Fatalf("accepted invalid config: %+v", classes)
			}
		})
	}
}

func TestTrafficClassBoundsListsBeforeCompiling(t *testing.T) {
	names := make([]string, trafficClassMaxValues+1)
	for i := range names {
		names[i] = "process" + strings.Repeat("x", i+1)
	}
	data := trafficClassFixture(map[string]any{
		"id": "many", "match": map[string]any{"processNames": names},
	})
	if _, err := parseTrafficClasses(data); err == nil {
		t.Fatal("accepted too many process names")
	}
	classes := make([]map[string]any, trafficClassMaxClasses+1)
	for i := range classes {
		classes[i] = map[string]any{
			"id":    fmt.Sprintf("class-%d", i),
			"match": map[string]any{"networks": []string{"tcp"}},
		}
	}
	if _, err := parseTrafficClasses(trafficClassFixture(classes...)); err == nil {
		t.Fatal("accepted too many classes")
	}
}

func TestTrafficClassRejectsJSONThatWeakensPredicates(t *testing.T) {
	for _, data := range []string{
		`{"schemaVersion":1,"SchemaVersion":1,"classes":[]}`,
		`{"schemaVersion":1,"classes":[],"classes":[]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","id":"b","match":{"networks":["tcp"]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"Networks":["tcp"]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":[null]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","priority":null,"match":{"networks":["tcp"]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":null,"networks":["tcp"]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":[],"networks":["tcp"]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":[1],"uids":[2]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":[1.5]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":[-1]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","match":{"uids":[4294967296]}}]}`,
		`{"schemaVersion":1,"classes":[{"id":"a","priority":2147483648,"match":{"networks":["tcp"]}}]}`,
	} {
		if _, err := parseTrafficClasses([]byte(data)); err == nil {
			t.Fatalf("accepted ambiguous config: %s", data)
		}
	}
}

func TestTrafficClassUIDAndPackageRequireExplicitIdentity(t *testing.T) {
	classes, err := parseTrafficClasses(trafficClassFixture(
		map[string]any{"id": "root", "match": map[string]any{"uids": []uint32{0}}},
		map[string]any{"id": "package", "match": map[string]any{"packages": []string{"com.example.browser"}}},
	))
	if err != nil {
		t.Fatal(err)
	}
	input := trafficClassInput{Metadata: &C.Metadata{Process: "com.example.browser"}}
	if _, _, ok := classes.classify(input); ok {
		t.Fatal("unresolved UID or overloaded Process became trusted identity")
	}
	input.UIDKnown = true
	if id, _, ok := classes.classify(input); !ok || id != "root" {
		t.Fatal("explicitly resolved UID zero did not match")
	}
	input.UIDKnown = false
	input.PackageName = "com.example.browser"
	if id, _, ok := classes.classify(input); !ok || id != "package" {
		t.Fatal("explicitly resolved package did not match")
	}
}

func TestTrafficClassAlternativesAreORedWithinDimension(t *testing.T) {
	classes, err := parseTrafficClasses(trafficClassFixture(map[string]any{
		"id": "alternatives", "match": map[string]any{
			"uids": []uint32{0, 42}, "networks": []string{"tcp", "udp"},
		},
	}))
	if err != nil {
		t.Fatal(err)
	}
	for _, uid := range []uint32{0, 42, 43} {
		input := trafficInput()
		input.Metadata.Uid = uid
		if _, _, ok := classes.classify(input); ok != (uid != 43) {
			t.Fatalf("wrong OR/AND match for UID %d", uid)
		}
	}
}

func TestTrafficClassPathSemanticsAndMissingPath(t *testing.T) {
	for _, path := range []string{".", "browser.exe", "../browser.exe"} {
		if _, err := parseTrafficClasses(trafficClassFixture(map[string]any{
			"id": "path", "match": map[string]any{"processPaths": []string{path}},
		})); err == nil {
			t.Fatalf("accepted relative path %q", path)
		}
	}
	path := trafficMetadata().ProcessPath
	classes, err := parseTrafficClasses(trafficClassFixture(map[string]any{
		"id": "path", "match": map[string]any{"processPaths": []string{path}},
	}))
	if err != nil {
		t.Fatal(err)
	}
	input := trafficInput()
	input.Metadata.ProcessPath = ""
	if _, _, ok := classes.classify(input); ok {
		t.Fatal("missing path matched")
	}
	input.Metadata.ProcessPath = filepath.Join(filepath.Dir(path), ".", filepath.Base(path))
	if _, _, ok := classes.classify(input); !ok {
		t.Fatal("clean absolute path did not match")
	}
	if runtime.GOOS != "windows" {
		actual, _ := normalizeClassProcessPath(`/opt/a\b/browser`)
		if actual != `/opt/a\b/browser` {
			t.Fatal("Unix backslash filename was rewritten")
		}
	}
}

func TestTrafficClassConfigDoesNotAliasInput(t *testing.T) {
	data := trafficClassFixture(map[string]any{
		"id": "browser", "priority": 7,
		"match": map[string]any{"processNames": []string{"browser.exe"}},
	})
	classes, err := parseTrafficClasses(data)
	if err != nil {
		t.Fatal(err)
	}
	for i := range data {
		data[i] = 'x'
	}
	id, priority, ok := classes.classify(trafficClassInput{Metadata: &C.Metadata{Process: "browser.exe"}})
	if !ok || id != "browser" || priority != 7 {
		t.Fatalf("config aliased input: id=%q priority=%d ok=%t", id, priority, ok)
	}
}
