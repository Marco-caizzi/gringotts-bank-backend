package config

import (
	"os"
	"sync"
)

const LogLevel = "debug"
const Environment = "utest"

// setup sets the environment variables needed in the configuration and resets singleton.
func setup() {
	// reset singleton first
	configuration = Configuration{}
	once = sync.Once{}

	_ = os.Setenv("LOG_LEVEL", LogLevel)
	_ = os.Setenv("ENV", Environment)
}

// resetConfig unsets the environment variables used in the configuration and resets singleton.
func resetConfig() {
	_ = os.Unsetenv("LOG_LEVEL")
	_ = os.Unsetenv("ENV")

	// reset singleton to force re-init in subsequent calls
	configuration = Configuration{}
	once = sync.Once{}
}
