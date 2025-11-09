package handler

import (
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/config"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/processor"
	"net/http"
)

// IHandler defines the HTTP contract for the health endpoint.
// It mirrors http.Handler to keep layers decoupled while allowing testing.
type IHandler interface {
	ServeHTTP(w http.ResponseWriter, r *http.Request)
}

// Handler implements the health endpoint using a HealthProcessor dependency.
type Handler struct {
	cfg  *config.Configuration
	proc processor.HealthProcessor
}

// NewHandler constructs a new handler exposing ServeHTTP.
func NewHandler(cfg *config.Configuration, proc processor.HealthProcessor) http.Handler {
	return &Handler{cfg: cfg, proc: proc}
}

const (
	bodyMethodNotAllowedMsg = "method not allowed"
	bodyInternalErrorMsg    = "internal error"
)

// ServeHTTP returns the health payload as JSON and only allows GET.
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeResponse(w, http.StatusMethodNotAllowed, Response{Message: bodyMethodNotAllowedMsg})
		return
	}

	results, err := h.proc.GetHealth()
	if err != nil {
		writeResponse(w, http.StatusInternalServerError, Response{Message: bodyInternalErrorMsg})
		return
	}

	// Return the JSON payload provided by the processor as-is.
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(results)
}
