package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestWebserverIsAccessible(t *testing.T) {
	// Set up the handler like in main
	mux := http.NewServeMux()
	mux.HandleFunc("/", welcomeHandler)

	// Test the basic root path
	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatalf("Failed to create request: %v", err)
	}

	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	// Check status code is OK (200)
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check the response body contains "Welcome to the blog"
	if !strings.Contains(rr.Body.String(), "Welcome to the blog") {
		t.Errorf("handler returned unexpected body: got %v want to contain %v",
			rr.Body.String(), "Welcome to the blog")
	}
}
