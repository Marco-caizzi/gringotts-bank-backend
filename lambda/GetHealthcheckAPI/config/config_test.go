package config

import "testing"

/*
* Test Cases
* 1 - Config Defaults and Normalization
* 2 - Config Requires Env
 */
func TestConfigDefaultsAndNormalization(t *testing.T) {
	setup()
	// override values to test normalization
	// LOG_LEVEL is already debug from setup, set a variant to test normalization path
	// Expect Warning -> warn
	resetConfig()
	// set env again with test values
	configuration = Configuration{}
	setup()
	// override to exercise normalization
	t.Setenv("LOG_LEVEL", "Warning")
	t.Setenv("ENV", "local")

	cfg := New()
	if cfg.Environment != "local" {
		t.Fatalf("expected ENV local got %s", cfg.Environment)
	}
	if cfg.LogLevel != "warn" {
		t.Fatalf("expected warn got %s", cfg.LogLevel)
	}
}

func TestConfigRequiresEnv(t *testing.T) {
	resetConfig()
	// ensure ENV absent
	t.Setenv("LOG_LEVEL", "info") // optional log level
	// remove ENV if testing framework set earlier
	t.Setenv("ENV", "")
	defer func() {
		if r := recover(); r == nil {
			t.Fatalf("expected panic when ENV missing")
		}
	}()
	_ = New() // should panic
}
