package handler

import (
	"errors"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/config"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/processor"
	"net/http"
	"testing"
)

// mockProcessor provides a successful implementation of HealthProcessor for tests.
type mockProcessor struct{}

func (m mockProcessor) GetHealth() ([]byte, error) { return []byte(`{"message":"OK"}`), nil }

// failingProcessor simulates an internal error from the business layer.
type failingProcessor struct{}

func (f failingProcessor) GetHealth() ([]byte, error) { return nil, errors.New("boom") }

// setup builds a handler with provided processor mock and prepares environment.
func setup(t *testing.T, proc processor.HealthProcessor) http.Handler {
	t.Helper()
	t.Setenv("ENV", "test")
	t.Setenv("LOG_LEVEL", "debug")
	cfg := config.New()
	return NewHandler(&cfg, proc)
}
