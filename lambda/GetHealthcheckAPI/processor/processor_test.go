package processor

import (
	"encoding/json"
	"testing"
)

func TestGetHealthPayload(t *testing.T) {
	// Use helper to initialize config and processor.
	p := newTestProcessor(t)

	data, err := p.GetHealth()
	if err != nil {
		t.Fatalf("GetHealth() error: %v", err)
	}
	var m map[string]any
	if err := json.Unmarshal(data, &m); err != nil {
		t.Fatalf("invalid json: %v", err)
	}
	if m["message"] != testResult.Message {
		t.Fatalf("unexpected message: %v", m["message"])
	}
}
