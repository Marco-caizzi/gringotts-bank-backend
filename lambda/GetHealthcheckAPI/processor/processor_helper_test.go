package processor

import (
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/config"
	"testing"
)

// testResult holds common expected values for assertions.
// Keeping these in one place improves readability and reuse across tests.
var testResult = struct {
	Message string
}{
	Message: "OK",
}

// init references testResult to avoid static analysis warnings in this file.
func init() { _ = testResult }

// newTestProcessor initializes environment variables, configuration, and returns
// the Processor via its interface for tests without spinning up the handler.
func newTestProcessor(t *testing.T) HealthProcessor {
	t.Helper()

	// Minimal environment to satisfy configuration contract
	t.Setenv("ENV", "test")
	t.Setenv("LOG_LEVEL", "debug")

	cfg := config.New()
	return NewProcessor(&cfg)
}
