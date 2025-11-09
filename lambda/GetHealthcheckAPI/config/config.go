package config

import (
	"os"
	"strings"
	"sync"
)

var (
	configuration Configuration
	once          sync.Once
)

// Configuration holds required environment variables for the lambda.
// - ENV: execution environment (local, dev, prod). Required.
// - LOG_LEVEL: logging level (debug|info|warn|error). Defaults to "info".
type Configuration struct {
	LogLevel    string
	Environment string
}

// New initializes configuration once and returns it.
func New() Configuration {
	once.Do(func() {
		configuration = initConfiguration()
	})
	return configuration
}

// initConfiguration reads and validates environment variables.
func initConfiguration() Configuration {
	cfg := Configuration{
		LogLevel:    os.Getenv("LOG_LEVEL"),
		Environment: os.Getenv("ENV"),
	}

	// Defaults
	if cfg.LogLevel == "" {
		cfg.LogLevel = "info"
	}
	cfg.LogLevel = normalizeLogLevel(cfg.LogLevel)

	// Validation
	if cfg.Environment == "" {
		panic("ENV variable required (e.g. local, dev, prod)")
	}

	return cfg
}

// normalizeLogLevel normalizes received log level string.
func normalizeLogLevel(lvl string) string {
	lvl = strings.ToLower(strings.TrimSpace(lvl))
	switch lvl {
	case "debug", "info", "warn", "warning", "error":
		if lvl == "warning" { // allow 'warning' -> 'warn'
			return "warn"
		}
		return lvl
	default:
		return "info"
	}
}
