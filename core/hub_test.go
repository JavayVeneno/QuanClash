package main

import "testing"

func TestNewDelayResult(t *testing.T) {
	tests := []struct {
		name     string
		delay    uint16
		timedOut bool
		want     int32
	}{
		{name: "successful test", delay: 120, want: 120},
		{name: "zero delay", delay: 0, want: -1},
		{name: "timed out with partial delay", delay: 120, timedOut: true, want: -1},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := newDelayResult("https://example.com", "node-a", tt.delay, tt.timedOut)
			if result.Url != "https://example.com" {
				t.Fatalf("Url = %q, want %q", result.Url, "https://example.com")
			}
			if result.Name != "node-a" {
				t.Fatalf("Name = %q, want %q", result.Name, "node-a")
			}
			if result.Value != tt.want {
				t.Fatalf("Value = %d, want %d", result.Value, tt.want)
			}
		})
	}
}
