package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
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

func TestWelcomePageIsDefault(t *testing.T) {
	// Set up the handler like in main
	mux := http.NewServeMux()
	mux.HandleFunc("/", welcomeHandler)

	// Test that the welcome page is shown at the root path
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

	// Check the response contains the welcome page elements
	body := rr.Body.String()
	if !strings.Contains(body, "Welcome to the blog") {
		t.Errorf("welcome page should contain 'Welcome to the blog', got: %s", body)
	}
	if !strings.Contains(body, "<h1>") {
		t.Errorf("welcome page should contain h1 tag, got: %s", body)
	}
	if !strings.Contains(body, "<!DOCTYPE html>") {
		t.Errorf("welcome page should be valid HTML, got: %s", body)
	}
}

func TestNewPostPageReachable(t *testing.T) {
	// Set up the handler like in main
	mux := http.NewServeMux()
	mux.HandleFunc("/new", newPostHandler)

	// Test that the new post page is reachable
	req, err := http.NewRequest("GET", "/new", nil)
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

	// Check the response contains the correct form elements
	body := rr.Body.String()
	if !strings.Contains(body, "Create a New Post") {
		t.Errorf("new post page should contain 'Create a New Post', got: %s", body)
	}
	if !strings.Contains(body, `name="title"`) {
		t.Errorf("new post page should contain title input field, got: %s", body)
	}
	if !strings.Contains(body, `name="body"`) {
		t.Errorf("new post page should contain body textarea field, got: %s", body)
	}
	if !strings.Contains(body, "Create Post") {
		t.Errorf("new post page should contain submit button, got: %s", body)
	}
}

func TestNewPostFormSubmissionPersists(t *testing.T) {
	// Clear the global posts slice before test
	posts = []Post{}

	// Set up the handler like in main
	mux := http.NewServeMux()
	mux.HandleFunc("/new", newPostHandler)

	// Create a POST request to submit a new post
	formData := strings.NewReader("title=Test+Title&body=Test+Body")
	req, err := http.NewRequest("POST", "/new", formData)
	if err != nil {
		t.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	// Check status code is OK (200)
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check that the post was persisted
	if len(posts) != 1 {
		t.Errorf("expected 1 post to be persisted, got %d", len(posts))
	} else {
		if posts[0].Title != "Test Title" {
			t.Errorf("expected post title to be 'Test Title', got '%s'", posts[0].Title)
		}
		if posts[0].Body != "Test Body" {
			t.Errorf("expected post body to be 'Test Body', got '%s'", posts[0].Body)
		}
		if posts[0].Created.IsZero() {
			t.Errorf("expected post created time to be set")
		}
	}

	// Check that the response indicates success
	if !strings.Contains(rr.Body.String(), "Post created") {
		t.Errorf("response should contain 'Post created', got: %s", rr.Body.String())
	}
}

func TestNavigateToPostByTitle(t *testing.T) {
	// Clear the global posts slice before test
	posts = []Post{}

	// Set up the handler like in main
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			welcomeHandler(w, r)
		} else if r.URL.Path == "/new" {
			newPostHandler(w, r)
		} else {
			postHandler(w, r)
		}
	})

	// Create a post with title "test post"
	testPost := Post{
		Title:   "test post",
		Body:    "This is a test post body",
		Created: time.Now(),
	}
	posts = append(posts, testPost)

	// Navigate to /test_post
	req, err := http.NewRequest("GET", "/test_post", nil)
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

	// Check that the response contains the post title and body
	body := rr.Body.String()
	if !strings.Contains(body, "test post") {
		t.Errorf("response should contain post title 'test post', got: %s", body)
	}
	if !strings.Contains(body, "This is a test post body") {
		t.Errorf("response should contain post body, got: %s", body)
	}
}
