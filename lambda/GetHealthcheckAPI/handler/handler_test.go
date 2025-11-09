package handler

import (
	"encoding/json"
	"errors"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/config"
	"net/http"
	"net/http/httptest"
	"testing"
)

// mockProcessor implements the processor interface used by Handler.
type mockProcessor struct{}

func (m mockProcessor) GetHealth() ([]byte, error) { return []byte(`{"message":"OK"}`), nil }

// failingProcessor simulates an internal error.
type failingProcessor struct{}

func (f failingProcessor) GetHealth() ([]byte, error) { return nil, errors.New("boom") }

func TestServeHTTP_OK(t *testing.T) {
	t.Setenv("ENV", "test")
	t.Setenv("LOG_LEVEL", "info")
	cfg := config.New()
	h := NewHandler(&cfg, mockProcessor{})

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	resp := rec.Result()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 got %d", resp.StatusCode)
	}
	var m map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&m); err != nil {
		t.Fatalf("invalid json: %v", err)
	}
	if m["message"] != "OK" {
		t.Fatalf("wrong message: %v", m["message"])
	}
}

func TestServeHTTP_MethodNotAllowed(t *testing.T) {
	t.Setenv("ENV", "test")
	t.Setenv("LOG_LEVEL", "debug")
	cfg := config.New()
	h := NewHandler(&cfg, mockProcessor{})

	req := httptest.NewRequest(http.MethodPost, "/health", nil)
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	resp := rec.Result()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Fatalf("expected 405 got %d", resp.StatusCode)
	}
}

func TestServeHTTP_InternalError(t *testing.T) {
	t.Setenv("ENV", "test")
	t.Setenv("LOG_LEVEL", "debug")
	cfg := config.New()
	h := NewHandler(&cfg, failingProcessor{})

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	resp := rec.Result()
	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("expected 500 got %d", resp.StatusCode)
	}
	var m map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&m); err != nil {
		t.Fatalf("invalid json: %v", err)
	}
	if m["message"] != "internal error" {
		t.Fatalf("unexpected message: %v", m["message"])
	}
}
