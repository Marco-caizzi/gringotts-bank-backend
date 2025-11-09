package config

import (
	"os"
	"sync"
	"testing"
)

func resetConfig() {
	once = sync.Once{}
	configuration = Configuration{}
}

func TestConfigDefaultsAndNormalization(t *testing.T) {
	resetConfig()
	_ = os.Setenv("ENV", "local")
	_ = os.Setenv("LOG_LEVEL", "Warning") // test normalization
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
	_ = os.Unsetenv("ENV")
	_ = os.Unsetenv("LOG_LEVEL")
	defer func() {
		if r := recover(); r == nil {
			t.Fatalf("expected panic when ENV missing")
		}
	}()
	_ = New() // should panic
}
