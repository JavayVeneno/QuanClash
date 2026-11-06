package main

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"slices"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

const (
	connectionUpdateMaxRecords = 4096
	connectionUpdateMaxBytes   = 8 * 1024 * 1024
	connectionUpdateTTL        = 30 * time.Second
	// At least three quarters of a nontrivial snapshot needing full records
	// favors resync. This is a bounded heuristic, not an exact byte estimate.
	connectionUpdateChurnMinRecords = 16
	connectionUpdateChurnMaxRetain  = 4
)

type connectionUpdateRequest struct {
	SchemaVersion int    `json:"schemaVersion"`
	Cursor        string `json:"cursor"`
}

func parseConnectionUpdateRequest(data any) (connectionUpdateRequest, error) {
	text, ok := data.(string)
	if !ok || len(text) > 256 {
		return connectionUpdateRequest{}, fmt.Errorf("invalid connection update request")
	}
	decoder := json.NewDecoder(bytes.NewBufferString(text))
	decoder.DisallowUnknownFields()
	var request connectionUpdateRequest
	if err := decoder.Decode(&request); err != nil {
		return request, fmt.Errorf("invalid connection update request")
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF || request.SchemaVersion != 1 {
		return request, fmt.Errorf("unsupported connection update request")
	}
	var fields map[string]any
	if err := json.Unmarshal([]byte(text), &fields); err != nil || fields == nil {
		return request, fmt.Errorf("invalid connection update request")
	}
	if value, exists := fields["cursor"]; exists {
		if _, ok := value.(string); !ok {
			return request, fmt.Errorf("invalid connection update cursor")
		}
	}
	if request.Cursor != "" {
		decoded, err := hex.DecodeString(request.Cursor)
		if err != nil || len(decoded) != 16 {
			return request, fmt.Errorf("invalid connection update cursor")
		}
	}
	return request, nil
}

type connectionCounters struct {
	ID       string `json:"id"`
	Upload   int64  `json:"upload"`
	Download int64  `json:"download"`
}

type connectionRemoval struct {
	connectionCounters
	FinalCountersVerified bool `json:"finalCountersVerified"`
}

type connectionUpdateResponse struct {
	SchemaVersion int                  `json:"schemaVersion"`
	Status        string               `json:"status"`
	Full          bool                 `json:"full"`
	BaseCursor    string               `json:"baseCursor"`
	Cursor        string               `json:"cursor"`
	SampledAt     string               `json:"sampledAt"`
	UploadTotal   int64                `json:"uploadTotal"`
	DownloadTotal int64                `json:"downloadTotal"`
	Upserted      []json.RawMessage    `json:"upserted"`
	Updated       []connectionCounters `json:"updated"`
	Removed       []connectionRemoval  `json:"removed"`
}

type connectionObservation struct {
	connectionCounters
	static json.RawMessage
	fields *connectionStaticRecord
}

type connectionStaticRecord struct {
	ID            string     `json:"id"`
	Metadata      C.Metadata `json:"metadata"`
	Start         time.Time  `json:"start"`
	Chains        C.Chain    `json:"chains"`
	ProviderChain C.Chain    `json:"providerChains"`
	Rule          string     `json:"rule"`
	RulePayload   string     `json:"rulePayload"`
}

func sameStrings(a, b []string) bool {
	return (a == nil) == (b == nil) && slices.Equal(a, b)
}

func cloneStrings(values []string) []string {
	if values == nil {
		return nil
	}
	result := make([]string, len(values))
	for i, value := range values {
		result[i] = strings.Clone(value)
	}
	return result
}

func sameConnectionMetadata(a, b *C.Metadata) bool {
	// Compare every JSON-visible field, not pointer identity or a hash. The
	// field-mutation test intentionally fails when an upstream field is added.
	return a.NetWork == b.NetWork && a.Type == b.Type && a.SrcIP == b.SrcIP && a.DstIP == b.DstIP &&
		sameStrings(a.SrcGeoIP, b.SrcGeoIP) && sameStrings(a.DstGeoIP, b.DstGeoIP) &&
		a.SrcIPASN == b.SrcIPASN && a.DstIPASN == b.DstIPASN && a.SrcPort == b.SrcPort && a.DstPort == b.DstPort &&
		a.InIP == b.InIP && a.InPort == b.InPort && a.InName == b.InName && a.InUser == b.InUser &&
		a.RematchName == b.RematchName && a.Host == b.Host && a.DNSMode == b.DNSMode && a.Uid == b.Uid &&
		a.Process == b.Process && a.ProcessPath == b.ProcessPath && a.SpecialProxy == b.SpecialProxy &&
		a.SpecialRules == b.SpecialRules && a.RemoteDst == b.RemoteDst && a.DSCP == b.DSCP && a.SniffHost == b.SniffHost
}

func (fields *connectionStaticRecord) matches(info *statistic.TrackerInfo) bool {
	return fields != nil && sameConnectionMetadata(&fields.Metadata, info.Metadata) && fields.Start == info.Start &&
		sameStrings(fields.Chains, info.Chain) && sameStrings(fields.ProviderChain, info.ProviderChain) &&
		fields.Rule == info.Rule && fields.RulePayload == info.RulePayload
}

func observeConnection(info *statistic.TrackerInfo) (connectionObservation, error) {
	if info == nil || info.Metadata == nil {
		return connectionObservation{}, fmt.Errorf("invalid tracker inspection record")
	}
	id := info.UUID.String()
	return observeConnectionID(info, id, connectionObservation{})
}

func observeConnectionID(info *statistic.TrackerInfo, id string, previous connectionObservation) (connectionObservation, error) {
	counters := connectionCounters{id, info.UploadTotal.Load(), info.DownloadTotal.Load()}
	if previous.ID == id && previous.fields.matches(info) {
		previous.connectionCounters = counters
		return previous, nil
	}
	metadata := *info.Metadata
	metadata.RawSrcAddr, metadata.RawDstAddr = nil, nil
	metadata.SrcGeoIP, metadata.DstGeoIP = cloneStrings(metadata.SrcGeoIP), cloneStrings(metadata.DstGeoIP)
	metadata.SrcIPASN, metadata.DstIPASN = strings.Clone(metadata.SrcIPASN), strings.Clone(metadata.DstIPASN)
	metadata.InName, metadata.InUser = strings.Clone(metadata.InName), strings.Clone(metadata.InUser)
	metadata.RematchName, metadata.Host = strings.Clone(metadata.RematchName), strings.Clone(metadata.Host)
	metadata.Process, metadata.ProcessPath = strings.Clone(metadata.Process), strings.Clone(metadata.ProcessPath)
	metadata.SpecialProxy, metadata.SpecialRules = strings.Clone(metadata.SpecialProxy), strings.Clone(metadata.SpecialRules)
	metadata.RemoteDst, metadata.SniffHost = strings.Clone(metadata.RemoteDst), strings.Clone(metadata.SniffHost)
	fields := &connectionStaticRecord{
		ID: id, Metadata: metadata, Start: info.Start,
		Chains: cloneStrings(info.Chain), ProviderChain: cloneStrings(info.ProviderChain),
		Rule: strings.Clone(info.Rule), RulePayload: strings.Clone(info.RulePayload),
	}
	static, err := json.Marshal(fields)
	if err != nil {
		return connectionObservation{}, err
	}
	return connectionObservation{
		connectionCounters: counters, static: static, fields: fields,
	}, nil
}

func (observation connectionObservation) chargedBytes() int {
	// Charge both detached JSON and typed comparison data. Cloned strings do
	// not pin arbitrarily large source backing buffers; slice headers are extra.
	return 2*len(observation.static) + len(observation.ID) + 1024 +
		16*(len(observation.fields.Metadata.SrcGeoIP)+len(observation.fields.Metadata.DstGeoIP)+
			len(observation.fields.Chains)+len(observation.fields.ProviderChain))
}

func (observation connectionObservation) fullRecord() json.RawMessage {
	// static is a validated JSON object; append scalar counters without parsing
	// it into a map or copying Go atomic values from TrackerInfo.
	record := make(json.RawMessage, 0, len(observation.static)+64)
	record = append(record, observation.static[:len(observation.static)-1]...)
	record = append(record, `,"upload":`...)
	record = strconv.AppendInt(record, observation.Upload, 10)
	record = append(record, `,"download":`...)
	record = strconv.AppendInt(record, observation.Download, 10)
	return append(record, '}')
}

type connectionUpdateCache struct {
	mutex   sync.Mutex
	cursor  string
	readAt  time.Time
	records map[string]connectionObservation
}

var connectionUpdates connectionUpdateCache

func (cache *connectionUpdateCache) reset() {
	cache.mutex.Lock()
	defer cache.mutex.Unlock()
	cache.cursor, cache.readAt, cache.records = "", time.Time{}, nil
}

func newConnectionUpdateResponse(status string, now time.Time) connectionUpdateResponse {
	return connectionUpdateResponse{
		SchemaVersion: 1, Status: status, Full: true, SampledAt: now.UTC().Format(time.RFC3339Nano),
		Upserted: []json.RawMessage{}, Updated: []connectionCounters{}, Removed: []connectionRemoval{},
	}
}

// One bounded latest snapshot, not an unbounded per-client event journal.
// Multiple clients or dropped replies cause full resync, never partial replay.
func (cache *connectionUpdateCache) query(request connectionUpdateRequest, now time.Time, collect func(func(*statistic.TrackerInfo) bool) error) (connectionUpdateResponse, error) {
	cache.mutex.Lock()
	defer cache.mutex.Unlock()
	result := newConnectionUpdateResponse("ready", now)
	next := make(map[string]connectionObservation, len(cache.records))
	totalBytes, overflow := 0, false
	var readErr error
	err := collect(func(info *statistic.TrackerInfo) bool {
		if len(next) >= connectionUpdateMaxRecords {
			overflow = true
			return false
		}
		if info == nil || info.Metadata == nil {
			readErr = fmt.Errorf("invalid tracker inspection record")
			return false
		}
		id := info.UUID.String()
		if _, exists := next[id]; exists {
			readErr = fmt.Errorf("duplicate connection observation")
			return false
		}
		record, err := observeConnectionID(info, id, cache.records[id])
		if err != nil {
			readErr = err
			return false
		}
		totalBytes += record.chargedBytes()
		if totalBytes > connectionUpdateMaxBytes {
			overflow = true
			return false
		}
		next[record.ID] = record
		return true
	})
	if err != nil {
		return result, err
	}
	if readErr != nil {
		return result, readErr
	}
	if overflow {
		cache.cursor, cache.readAt, cache.records = "", time.Time{}, nil
		return newConnectionUpdateResponse("fallback-required", now), nil
	}
	result.Full = request.Cursor == "" || request.Cursor != cache.cursor || cache.records == nil ||
		now.Sub(cache.readAt) >= connectionUpdateTTL || now.Before(cache.readAt)
	if !result.Full {
		result.BaseCursor = cache.cursor
	}
	ids := make([]string, 0, len(next))
	for id := range next {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	removed := make([]string, 0)
	if !result.Full {
		for id := range cache.records {
			if _, exists := next[id]; !exists {
				removed = append(removed, id)
			}
		}
		sort.Strings(removed)
		recordChurn := 0
		for _, id := range ids {
			record := next[id]
			// observeConnectionID reuses the previous fields pointer exactly
			// when every inspected field matched, so inequality means churn.
			previous, exists := cache.records[id]
			if !exists || record.fields != previous.fields {
				recordChurn++
			}
		}
		// Count only records requiring upserts, not removals: a half replacement
		// still benefits from delta even though old/new IDs are both operations.
		if len(next) >= connectionUpdateChurnMinRecords &&
			(len(next)-recordChurn)*connectionUpdateChurnMaxRetain <= len(next) {
			result.Full = true
			// A full replacement must not advertise a delta base cursor.
			result.BaseCursor = ""
		}
	}
	for _, id := range ids {
		record := next[id]
		previous, exists := cache.records[id]
		if result.Full || !exists || record.fields != previous.fields {
			result.Upserted = append(result.Upserted, record.fullRecord())
		} else if record.Upload != previous.Upload || record.Download != previous.Download {
			result.Updated = append(result.Updated, record.connectionCounters)
		}
	}
	if !result.Full {
		for _, id := range removed {
			// Manager.Range cannot supply final counts of already closed trackers.
			result.Removed = append(result.Removed, connectionRemoval{connectionCounters: cache.records[id].connectionCounters})
		}
	}
	var token [16]byte
	if _, err := rand.Read(token[:]); err != nil {
		return result, err
	}
	result.Cursor = hex.EncodeToString(token[:])
	cache.cursor, cache.readAt, cache.records = result.Cursor, now, next
	return result, nil
}

func handleGetConnectionUpdates(data any) (connectionUpdateResponse, error) {
	request, err := parseConnectionUpdateRequest(data)
	if err != nil {
		return connectionUpdateResponse{}, err
	}
	runLock.Lock()
	defer runLock.Unlock()
	now := time.Now()
	if !isInit || currentConfig == nil {
		connectionUpdates.reset()
		return newConnectionUpdateResponse("inactive", now), nil
	}
	result, err := connectionUpdates.query(request, now, func(accept func(*statistic.TrackerInfo) bool) error {
		statistic.DefaultManager.Range(func(tracker statistic.Tracker) bool {
			return accept(tracker.Info())
		})
		return nil
	})
	if err == nil {
		result.UploadTotal, result.DownloadTotal = statistic.DefaultManager.Total()
	}
	return result, err
}
