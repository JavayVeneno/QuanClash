package main

import (
	"encoding/json"
	"fmt"
	"math"
	"net"
	"net/netip"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gofrs/uuid/v5"
	"github.com/metacubex/mihomo/common/atomic"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

func updateFixture(index int) *statistic.TrackerInfo {
	return &statistic.TrackerInfo{
		UUID:     uuid.Must(uuid.FromString(fmt.Sprintf("00000000-0000-4000-8000-%012d", index))),
		Metadata: &C.Metadata{NetWork: C.TCP, Type: C.SOCKS5, SrcIP: netip.MustParseAddr("127.0.0.1"), DstIP: netip.MustParseAddr("127.0.0.1"), Host: "example.invalid", SrcPort: 12345, DstPort: 443},
		Start:    time.Unix(1700000000, 0), Chain: C.Chain{"DIRECT"}, Rule: "Match",
		UploadTotal: atomic.NewInt64(10), DownloadTotal: atomic.NewInt64(20),
	}
}

func queryUpdateFixture(cache *connectionUpdateCache, cursor string, now time.Time, infos ...*statistic.TrackerInfo) (connectionUpdateResponse, error) {
	return cache.query(connectionUpdateRequest{SchemaVersion: 1, Cursor: cursor}, now, func(accept func(*statistic.TrackerInfo) bool) error {
		for _, info := range infos {
			if !accept(info) {
				break
			}
		}
		return nil
	})
}

func TestConnectionUpdateRequestValidation(t *testing.T) {
	for _, data := range []any{nil, 1, "", "null", "{}", `{"schemaVersion":2}`, `{"schemaVersion":1,"cursor":null}`,
		`{"schemaVersion":1,"cursor":true}`, `{"schemaVersion":1,"cursor":"bad"}`, `{"schemaVersion":1,"extra":true}`,
		`{"schemaVersion":1} {}`, strings.Repeat(" ", 257)} {
		if _, err := parseConnectionUpdateRequest(data); err == nil {
			t.Fatalf("accepted request: %v", data)
		}
	}
	for _, data := range []string{`{"schemaVersion":1}`, `{"schemaVersion":1,"cursor":""}`, `{"schemaVersion":1,"cursor":"00000000000000000000000000000000"}`} {
		if _, err := parseConnectionUpdateRequest(data); err != nil {
			t.Fatal(err)
		}
	}
}

func TestConnectionObservationMatchesLegacyRecord(t *testing.T) {
	info := updateFixture(1)
	info.Metadata.DstGeoIP = []string{"US"}
	info.ProviderChain = C.Chain{"provider"}
	observed, err := observeConnection(info)
	if err != nil {
		t.Fatal(err)
	}
	legacy, err := json.Marshal(info)
	if err != nil {
		t.Fatal(err)
	}
	var expected, actual map[string]any
	if json.Unmarshal(legacy, &expected) != nil || json.Unmarshal(observed.fullRecord(), &actual) != nil || !reflect.DeepEqual(expected, actual) {
		t.Fatalf("full upsert is not legacy-compatible: expected=%v actual=%v", expected, actual)
	}
	info.Metadata.DstGeoIP[0] = "changed"
	info.ProviderChain[0] = "changed"
	info.UploadTotal.Add(999)
	if strings.Contains(string(observed.static), "changed") || observed.Upload != 10 {
		t.Fatal("observation retained mutable metadata/chains/counters")
	}
}

func TestConnectionUpdatesDetectEveryMetadataField(t *testing.T) {
	typeOfMetadata := reflect.TypeOf(C.Metadata{})
	for i := 0; i < typeOfMetadata.NumField(); i++ {
		field := typeOfMetadata.Field(i)
		if field.Tag.Get("json") == "-" {
			continue
		}
		t.Run(field.Name, func(t *testing.T) {
			var cache connectionUpdateCache
			info, now := updateFixture(1), time.Now()
			first, err := queryUpdateFixture(&cache, "", now, info)
			if err != nil {
				t.Fatal(err)
			}
			value := reflect.ValueOf(info.Metadata).Elem().Field(i)
			switch value.Kind() {
			case reflect.String:
				value.SetString(value.String() + "changed")
			case reflect.Int:
				value.SetInt(value.Int() + 1)
			case reflect.Uint8, reflect.Uint16, reflect.Uint32:
				value.SetUint(value.Uint() + 1)
			case reflect.Slice:
				if value.Type() != reflect.TypeOf([]string{}) {
					t.Fatal("add coverage for new metadata slice type")
				}
				value.Set(reflect.ValueOf([]string{"changed"}))
			default:
				if value.Type() != reflect.TypeOf(netip.Addr{}) {
					t.Fatal("add coverage for new metadata field type")
				}
				value.Set(reflect.ValueOf(netip.MustParseAddr("2001:db8::1")))
			}
			second, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), info)
			if err != nil || second.Full || len(second.Upserted) != 1 || len(second.Updated)+len(second.Removed) != 0 {
				t.Fatalf("changed JSON field not upserted: %+v, %v", second, err)
			}
			legacy, err := json.Marshal(info)
			if err != nil {
				t.Fatal(err)
			}
			var expected, actual any
			if json.Unmarshal(legacy, &expected) != nil || json.Unmarshal(second.Upserted[0], &actual) != nil || !reflect.DeepEqual(expected, actual) {
				t.Fatal("metadata upsert diverges from legacy JSON")
			}
			third, err := queryUpdateFixture(&cache, second.Cursor, now.Add(2*time.Second), info)
			if err != nil || len(third.Upserted)+len(third.Updated)+len(third.Removed) != 0 {
				t.Fatal("unchanged metadata re-emitted")
			}
		})
	}
}

func TestConnectionUpdatesDetectEveryTrackerField(t *testing.T) {
	typeOfTracker := reflect.TypeOf(statistic.TrackerInfo{})
	for i := 0; i < typeOfTracker.NumField(); i++ {
		field := typeOfTracker.Field(i)
		if field.Name == "UUID" || field.Name == "Metadata" || field.Name == "UploadTotal" || field.Name == "DownloadTotal" {
			continue
		}
		t.Run(field.Name, func(t *testing.T) {
			var cache connectionUpdateCache
			info, now := updateFixture(1), time.Now()
			first, err := queryUpdateFixture(&cache, "", now, info)
			if err != nil {
				t.Fatal(err)
			}
			value := reflect.ValueOf(info).Elem().Field(i)
			switch value.Kind() {
			case reflect.String:
				value.SetString("changed")
			case reflect.Slice:
				if value.Type() != reflect.TypeOf(C.Chain{}) {
					t.Fatal("add coverage for new tracker slice type")
				}
				value.Set(reflect.ValueOf(C.Chain{"changed"}))
			default:
				if value.Type() != reflect.TypeOf(time.Time{}) {
					t.Fatal("add coverage for new tracker field type")
				}
				value.Set(reflect.ValueOf(info.Start.Add(time.Second)))
			}
			second, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), info)
			if err != nil || len(second.Upserted) != 1 || len(second.Updated) != 0 {
				t.Fatalf("changed tracker field not upserted: %+v, %v", second, err)
			}
		})
	}
}

func TestConnectionUpdatesDetachedSlicesAndNilEmptyChanges(t *testing.T) {
	for _, name := range []string{"sourceGeoIP", "destinationGeoIP", "chains", "providerChains"} {
		t.Run(name, func(t *testing.T) {
			var cache connectionUpdateCache
			info, now := updateFixture(1), time.Now()
			var values *[]string
			switch name {
			case "sourceGeoIP":
				values = &info.Metadata.SrcGeoIP
			case "destinationGeoIP":
				values = &info.Metadata.DstGeoIP
			case "chains":
				values = (*[]string)(&info.Chain)
			case "providerChains":
				values = (*[]string)(&info.ProviderChain)
			}
			*values = nil
			result, err := queryUpdateFixture(&cache, "", now, info)
			if err != nil {
				t.Fatal(err)
			}
			for _, next := range [][]string{{}, {"original"}, {"changed"}, nil} {
				if len(*values) == 1 && len(next) == 1 {
					(*values)[0] = next[0]
				} else {
					*values = next
				}
				now = now.Add(time.Second)
				result, err = queryUpdateFixture(&cache, result.Cursor, now, info)
				if err != nil || len(result.Upserted) != 1 {
					t.Fatalf("slice mutation/nil/empty change lost: %+v, %v", result, err)
				}
			}
		})
	}
}

func TestConnectionUpdatesReuseOnlyDetachedUnchangedFields(t *testing.T) {
	var cache connectionUpdateCache
	info, now := updateFixture(1), time.Now()
	info.Metadata.RawSrcAddr = &net.TCPAddr{IP: net.ParseIP("127.0.0.1"), Port: 1}
	first, err := queryUpdateFixture(&cache, "", now, info)
	if err != nil {
		t.Fatal(err)
	}
	previous := cache.records[info.UUID.String()]
	if previous.fields.Metadata.RawSrcAddr != nil || previous.fields.Metadata.RawDstAddr != nil {
		t.Fatal("cache retained raw address object")
	}
	info.Metadata.RawSrcAddr = &net.TCPAddr{Port: 2}
	info.UploadTotal.Store(math.MaxInt64)
	info.DownloadTotal.Store(math.MinInt64)
	second, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), info)
	if err != nil || len(second.Upserted) != 0 || len(second.Updated) != 1 || cache.records[info.UUID.String()].fields != previous.fields {
		t.Fatal("unchanged visible fields were reserialized or counters were lost")
	}
	full, err := queryUpdateFixture(&cache, "", now.Add(2*time.Second), info)
	if err != nil || len(full.Upserted) != 1 {
		t.Fatal(err)
	}
	var counters connectionCounters
	if json.Unmarshal(full.Upserted[0], &counters) != nil || counters.Upload != math.MaxInt64 || counters.Download != math.MinInt64 {
		t.Fatal("full encoding corrupted integer boundaries")
	}
	full.Upserted[0][0] = 'x'
	if !json.Valid(cache.records[info.UUID.String()].static) {
		t.Fatal("full response aliases retained JSON")
	}
}

func TestConnectionUpdatesFullCountersMetadataAndRemoval(t *testing.T) {
	var cache connectionUpdateCache
	now := time.Now()
	a, b := updateFixture(1), updateFixture(2)
	first, err := queryUpdateFixture(&cache, "", now, a)
	if err != nil || !first.Full || first.BaseCursor != "" || first.Cursor == "" || len(first.Upserted) != 1 {
		t.Fatalf("first snapshot: %+v, %v", first, err)
	}
	var record map[string]any
	if err := json.Unmarshal(first.Upserted[0], &record); err != nil || record["upload"] != float64(10) || record["download"] != float64(20) || record["id"] != a.UUID.String() {
		t.Fatalf("invalid full record: %v, %v", record, err)
	}
	a.UploadTotal.Add(5)
	second, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), a, b)
	if err != nil || second.Full || second.BaseCursor != first.Cursor || len(second.Upserted) != 1 || len(second.Updated) != 1 || second.Updated[0].Upload != 15 {
		t.Fatalf("counter/add delta: %+v, %v", second, err)
	}
	a.Metadata.Host = "changed.invalid"
	third, err := queryUpdateFixture(&cache, second.Cursor, now.Add(2*time.Second), a, b)
	if err != nil || len(third.Upserted) != 1 || len(third.Updated) != 0 || !strings.Contains(string(third.Upserted[0]), "changed.invalid") {
		t.Fatalf("metadata delta: %+v, %v", third, err)
	}
	fourth, err := queryUpdateFixture(&cache, third.Cursor, now.Add(3*time.Second), b)
	if err != nil || len(fourth.Removed) != 1 || fourth.Removed[0].ID != a.UUID.String() || fourth.Removed[0].Upload != 15 || fourth.Removed[0].FinalCountersVerified {
		t.Fatalf("removal must be last observed, not final accounting: %+v, %v", fourth, err)
	}
	// Cache JSON must not alias the returned packet.
	first.Upserted[0][0] = 'x'
	fifth, err := queryUpdateFixture(&cache, fourth.Cursor, now.Add(4*time.Second), b)
	if err != nil || len(fifth.Upserted)+len(fifth.Updated)+len(fifth.Removed) != 0 || fifth.Cursor == fourth.Cursor {
		t.Fatalf("unchanged delta: %+v, %v", fifth, err)
	}
}

func TestConnectionUpdatesResynchronizeAndInvalidate(t *testing.T) {
	for _, reason := range []string{"missed-response", "other-client", "expired", "clock-backward", "reset"} {
		t.Run(reason, func(t *testing.T) {
			var cache connectionUpdateCache
			now := time.Now()
			info := updateFixture(1)
			first, _ := queryUpdateFixture(&cache, "", now, info)
			when, cursor := now.Add(time.Second), first.Cursor
			switch reason {
			case "missed-response":
				_, _ = queryUpdateFixture(&cache, cursor, when, info)
			case "other-client":
				_, _ = queryUpdateFixture(&cache, "", when, info)
			case "expired":
				when = now.Add(connectionUpdateTTL)
			case "clock-backward":
				when = now.Add(-time.Second)
			case "reset":
				cache.reset()
			}
			result, err := queryUpdateFixture(&cache, cursor, when, info)
			if err != nil || !result.Full || result.BaseCursor != "" || len(result.Upserted) != 1 || len(result.Removed) != 0 {
				t.Fatalf("must atomically replace client state: %+v, %v", result, err)
			}
		})
	}
}

func TestConnectionUpdatesBoundCacheAndRejectPartialRecords(t *testing.T) {
	var cache connectionUpdateCache
	now := time.Now()
	info := updateFixture(1)
	first, _ := queryUpdateFixture(&cache, "", now, info)
	if _, err := queryUpdateFixture(&cache, first.Cursor, now, info, info); err == nil || cache.cursor != first.Cursor {
		t.Fatal("duplicate collection must fail without advancing state")
	}
	if _, err := queryUpdateFixture(&cache, first.Cursor, now, nil); err == nil || cache.cursor != first.Cursor {
		t.Fatal("invalid collection must fail without advancing state")
	}
	for _, limit := range []string{"records", "bytes"} {
		result, err := cache.query(connectionUpdateRequest{SchemaVersion: 1}, now, func(accept func(*statistic.TrackerInfo) bool) error {
			for i := 0; i <= connectionUpdateMaxRecords; i++ {
				info := updateFixture(i)
				if limit == "bytes" {
					info.Metadata.Host = strings.Repeat("x", connectionUpdateMaxBytes)
				}
				if !accept(info) {
					break
				}
			}
			return nil
		})
		if err != nil || result.Status != "fallback-required" || result.Cursor != "" || len(result.Upserted) != 0 || cache.records != nil {
			t.Fatalf("%s limit silently truncated or retained cache: %+v, %v", limit, result, err)
		}
	}
}

func TestConnectionUpdatesChurnPolicyReturnsFullResync(t *testing.T) {
	build := func(base byte, count int) []*statistic.TrackerInfo {
		infos := make([]*statistic.TrackerInfo, 0, count)
		for i := 0; i < count; i++ {
			info := updateFixture(i + 1)
			info.UUID[0] = base
			infos = append(infos, info)
		}
		return infos
	}
	cases := []struct {
		name     string
		size     int
		keep     int
		retract  bool
		recount  bool
		mutfield bool
		wantFull bool
	}{
		{name: "all replaced", size: 128, keep: 0, wantFull: true},
		{name: "all metadata changed", size: 128, keep: 128, mutfield: true, wantFull: true},
		{name: "retain boundary one quarter", size: 128, keep: 32, wantFull: true},
		{name: "retain above boundary", size: 128, keep: 33},
		{name: "half replaced", size: 128, keep: 64},
		{name: "small snapshot all replaced", size: 8, keep: 0},
		{name: "below minimum all replaced", size: 15, keep: 0},
		{name: "minimum snapshot all replaced", size: 16, keep: 0, wantFull: true},
		{name: "odd size below threshold", size: 17, keep: 5},
		{name: "odd size above threshold", size: 17, keep: 4, wantFull: true},
		{name: "removals only", size: 128, keep: 16, retract: true},
		{name: "remove all", size: 128, keep: 0, retract: true},
		{name: "counters only", size: 128, keep: 128, recount: true},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			var cache connectionUpdateCache
			now := time.Now()
			previous := build(1, testCase.size)
			first, err := queryUpdateFixture(&cache, "", now, previous...)
			if err != nil || !first.Full || len(first.Upserted) != testCase.size {
				t.Fatalf("initial full: %+v, %v", first, err)
			}
			next := build(2, testCase.size)
			for i := 0; i < testCase.keep; i++ {
				next[i] = previous[i]
			}
			if testCase.mutfield {
				for _, info := range next {
					info.Metadata.Host = "changed.invalid"
				}
			}
			if testCase.retract {
				next = next[:testCase.keep]
			}
			if testCase.recount {
				next = previous
				for _, info := range next {
					info.UploadTotal.Add(1)
				}
			}
			second, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), next...)
			if err != nil {
				t.Fatal(err)
			}
			if second.Full != testCase.wantFull || second.Status != "ready" || second.Cursor == "" {
				t.Fatalf("policy shape: full=%t want=%t status=%s base=%q cursorEmpty=%t up=%d upd=%d rem=%d", second.Full, testCase.wantFull, second.Status, second.BaseCursor, second.Cursor == "", len(second.Upserted), len(second.Updated), len(second.Removed))
			}
			if second.Full {
				if second.BaseCursor != "" || len(second.Upserted) != len(next) || len(second.Updated) != 0 || len(second.Removed) != 0 {
					t.Fatalf("full replacement must not carry counters/removals: upserted=%d updated=%d removed=%d base=%q", len(second.Upserted), len(second.Updated), len(second.Removed), second.BaseCursor)
				}
			} else {
				wantUpserted, wantUpdated, wantRemoved := testCase.size-testCase.keep, 0, testCase.size-testCase.keep
				if testCase.retract {
					wantUpserted = 0
				}
				if testCase.recount {
					wantUpdated = testCase.size
				}
				if second.BaseCursor != first.Cursor || len(second.Upserted) != wantUpserted || len(second.Updated) != wantUpdated || len(second.Removed) != wantRemoved {
					t.Fatalf("delta shape: upserted=%d updated=%d removed=%d base=%q", len(second.Upserted), len(second.Updated), len(second.Removed), second.BaseCursor)
				}
			}
			third, err := queryUpdateFixture(&cache, second.Cursor, now.Add(2*time.Second), next...)
			if err != nil || third.Full || third.BaseCursor != second.Cursor || third.Cursor == "" || third.Cursor == second.Cursor || len(third.Upserted)+len(third.Updated)+len(third.Removed) != 0 {
				t.Fatalf("next poll must reuse the advanced baseline: %+v, %v", third, err)
			}
		})
	}
}

func TestConnectionUpdatesFailedCollectionPreservesDetachedBaseline(t *testing.T) {
	var cache connectionUpdateCache
	info, now := updateFixture(1), time.Now()
	first, err := queryUpdateFixture(&cache, "", now, info)
	if err != nil {
		t.Fatal(err)
	}
	old := cache.records[info.UUID.String()]
	info.UploadTotal.Add(5)
	if _, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), info, nil); err == nil || cache.cursor != first.Cursor || cache.records[info.UUID.String()].Upload != old.Upload {
		t.Fatal("failed scan advanced cached counters")
	}
	info.Metadata.Host = "changed.invalid"
	if _, err := queryUpdateFixture(&cache, first.Cursor, now.Add(time.Second), info, info); err == nil || cache.records[info.UUID.String()].fields != old.fields {
		t.Fatal("failed scan advanced cached metadata")
	}
	info.Start = time.Date(10000, 1, 1, 0, 0, 0, 0, time.UTC)
	if _, err := queryUpdateFixture(&cache, first.Cursor, now, info); err == nil || cache.cursor != first.Cursor {
		t.Fatal("JSON encoding failure advanced cursor")
	}
}

func TestConnectionUpdatesConcurrentQueries(t *testing.T) {
	var cache connectionUpdateCache
	var workers sync.WaitGroup
	for i := 0; i < 8; i++ {
		workers.Add(1)
		go func() {
			defer workers.Done()
			cursor := ""
			for j := 0; j < 30; j++ {
				result, err := queryUpdateFixture(&cache, cursor, time.Now(), updateFixture(1))
				if err != nil || result.Cursor == "" || (!result.Full && result.BaseCursor != cursor) {
					t.Error("concurrent client received invalid cursor chain")
					return
				}
				cursor = result.Cursor
			}
		}()
	}
	workers.Wait()
}

func TestConnectionUpdatesInactiveAndInvalidRequests(t *testing.T) {
	initialized, active := isInit, currentConfig
	t.Cleanup(func() { isInit, currentConfig = initialized, active; connectionUpdates.reset() })
	isInit = false
	result, err := handleGetConnectionUpdates(`{"schemaVersion":1}`)
	if err != nil || result.Status != "inactive" || result.Cursor != "" || len(result.Upserted) != 0 {
		t.Fatalf("inactive: %+v, %v", result, err)
	}
	if _, err := handleGetConnectionUpdates(`{"schemaVersion":2}`); err == nil {
		t.Fatal("invalid request was accepted")
	}
}

func TestConnectionUpdatesRejectedReloadPreservesCursor(t *testing.T) {
	preserveConfigState(t)
	connectionUpdates.reset()
	t.Cleanup(connectionUpdates.reset)
	first, err := queryUpdateFixture(&connectionUpdates, "", time.Now(), updateFixture(1))
	if err != nil {
		t.Fatal(err)
	}
	if err := applyConfig(defaultSetupParams()); err == nil {
		t.Fatal("missing config reload was accepted")
	}
	if connectionUpdates.cursor != first.Cursor {
		t.Fatal("parse rejection invalidated a live cursor")
	}
	params, _ := json.Marshal(InitParams{HomeDir: t.TempDir(), Version: 1})
	if !handleInitClash(string(params)) || connectionUpdates.records != nil || connectionUpdates.cursor != "" {
		t.Fatal("successful reinitialization retained inspection state")
	}
}

func BenchmarkConnectionInspectionEncoding(b *testing.B) {
	infos := make([]*statistic.TrackerInfo, 128)
	for i := range infos {
		infos[i] = updateFixture(i + 1)
	}
	b.Run("legacy-full-128", func(b *testing.B) {
		b.ReportAllocs()
		for i := 0; i < b.N; i++ {
			data, err := json.Marshal(&statistic.Snapshot{Connections: infos})
			if err != nil {
				b.Fatal(err)
			}
			b.ReportMetric(float64(len(data)), "wire-B/op")
		}
	})
	b.Run("delta-counters-128", func(b *testing.B) {
		var cache connectionUpdateCache
		first, err := queryUpdateFixture(&cache, "", time.Now(), infos...)
		if err != nil {
			b.Fatal(err)
		}
		cursor := first.Cursor
		b.ReportAllocs()
		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			for _, info := range infos {
				info.UploadTotal.Add(1)
			}
			result, err := queryUpdateFixture(&cache, cursor, time.Now(), infos...)
			if err != nil {
				b.Fatal(err)
			}
			cursor = result.Cursor
			data, err := json.Marshal(result)
			if err != nil {
				b.Fatal(err)
			}
			b.ReportMetric(float64(len(data)), "wire-B/op")
		}
	})
}

// Paired cold/full/quiet/churn costs, not packet-forwarding performance.
func BenchmarkConnectionInspectionWorkloads(b *testing.B) {
	for _, workload := range []string{"initial-full", "resync-full", "unchanged", "metadata-churn", "membership-churn"} {
		for _, path := range []string{"legacy", "updates"} {
			b.Run(workload+"/"+path+"-128", func(b *testing.B) {
				infos := make([]*statistic.TrackerInfo, 128)
				for i := range infos {
					infos[i] = updateFixture(i + 1)
				}
				var cache connectionUpdateCache
				cursor := ""
				if path == "updates" && workload != "initial-full" {
					first, err := queryUpdateFixture(&cache, "", time.Now(), infos...)
					if err != nil {
						b.Fatal(err)
					}
					cursor = first.Cursor
				}
				b.ReportAllocs()
				b.ResetTimer()
				for i := 0; i < b.N; i++ {
					if workload == "metadata-churn" {
						host := "a.invalid"
						if i%2 == 0 {
							host = "b.invalid"
						}
						for _, info := range infos {
							info.Metadata.Host = host
						}
					} else if workload == "membership-churn" {
						for _, info := range infos {
							// Alternate all identities without fixture construction.
							info.UUID[0] = byte(i%2 + 1)
						}
					}
					var data []byte
					var err error
					if path == "legacy" {
						data, err = json.Marshal(&statistic.Snapshot{Connections: infos})
					} else {
						if workload == "initial-full" {
							cache.reset()
							cursor = ""
						} else if workload == "resync-full" {
							cursor = ""
						}
						var result connectionUpdateResponse
						result, err = queryUpdateFixture(&cache, cursor, time.Now(), infos...)
						if err == nil {
							cursor = result.Cursor
							data, err = json.Marshal(result)
						}
					}
					if err != nil {
						b.Fatal(err)
					}
					b.ReportMetric(float64(len(data)), "wire-B/op")
				}
			})
		}
	}
}
