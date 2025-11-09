package handler

import (
	"encoding/json"
	"net/http"
)

// Response is the canonical JSON envelope for simple lambda HTTP replies.
type Response struct {
	Message string `json:"message"`
}

// writeResponse writes a JSON response with status code and appropriate headers.
// It overwrites Content-Type to application/json.
func writeResponse(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(data)
}
