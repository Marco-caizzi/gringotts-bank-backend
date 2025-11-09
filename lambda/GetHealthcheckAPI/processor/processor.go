package processor

import (
	"encoding/json"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/config"
)

// HealthProcessor defines the business operations exposed by this layer.
// Adding this interface allows upper layers (handlers) and tests to depend
// on an abstraction rather than the concrete implementation.
// It keeps the contract minimal and focused on the health use case.
type HealthProcessor interface {
	GetHealth() ([]byte, error)
}

// Processor contains dependencies for business logic implementing HealthProcessor.
type Processor struct {
	cfg *config.Configuration
}

// NewProcessor creates a new processor instance.
func NewProcessor(cfg *config.Configuration) *Processor {
	return &Processor{cfg: cfg}
}

// GetHealth builds the simple healthcheck response.
func (p *Processor) GetHealth() ([]byte, error) {
	payload := map[string]any{
		"message": "OK",
	}
	return json.Marshal(payload)
}
