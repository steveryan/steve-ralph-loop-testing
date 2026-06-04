package main

import (
	"fmt"
	"net/http"
	"time"
)

type Post struct {
	Title   string
	Body    string
	Created time.Time
}

var posts []Post

func welcomeHandler(w http.ResponseWriter, r *http.Request) {
	html := `<!DOCTYPE html>
<html>
<head>
	<title>Blog</title>
</head>
<body>
	<h1>Welcome to the blog</h1>
</body>
</html>`
	w.Header().Set("Content-Type", "text/html")
	fmt.Fprint(w, html)
}

func newPostHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "GET" {
		html := `<!DOCTYPE html>
<html>
<head>
	<title>New Post</title>
</head>
<body>
	<h1>Create a New Post</h1>
	<form method="post">
		<label>Title:</label>
		<input type="text" name="title" required></input>
		<br><br>
		<label>Body:</label>
		<textarea name="body" required></textarea>
		<br><br>
		<button type="submit">Create Post</button>
	</form>
</body>
</html>`
		w.Header().Set("Content-Type", "text/html")
		fmt.Fprint(w, html)
	} else if r.Method == "POST" {
		r.ParseForm()
		title := r.FormValue("title")
		body := r.FormValue("body")

		post := Post{
			Title:   title,
			Body:    body,
			Created: time.Now(),
		}
		posts = append(posts, post)

		w.Header().Set("Content-Type", "text/html")
		fmt.Fprintf(w, "Post created: %s", title)
	}
}

func main() {
	http.HandleFunc("/", welcomeHandler)
	http.HandleFunc("/new", newPostHandler)

	fmt.Println("Server running on http://localhost:8080")
	http.ListenAndServe(":8080", nil)
}
