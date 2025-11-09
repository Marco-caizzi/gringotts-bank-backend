package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

/*
* Test Cases (Handler)
* 1 - ServeHTTP_OK: Returns 200 and JSON {"message":"OK"} on GET.
* 2 - ServeHTTP_MethodNotAllowed: Returns 405 for non-GET method.
* 3 - ServeHTTP_InternalError: Returns 500 and error JSON when processor fails.
 */

func TestServeHTTP_OK(t *testing.T) {
	h := setup(t, mockProcessor{})

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
	h := setup(t, mockProcessor{})

	req := httptest.NewRequest(http.MethodPost, "/health", nil)
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	resp := rec.Result()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Fatalf("expected 405 got %d", resp.StatusCode)
	}
}

func TestServeHTTP_InternalError(t *testing.T) {
	h := setup(t, failingProcessor{})

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
