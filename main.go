package main

import (
	"fmt"
	"net/http"
	"strings"
	"time"
)

type Post struct {
	Title   string
	Body    string
	Created time.Time
}

var posts []Post

func welcomeHandler(w http.ResponseWriter, r *http.Request) {
	// Get the 10 most recent posts (sorted newest first)
	recentPosts := posts
	if len(recentPosts) > 10 {
		recentPosts = recentPosts[len(recentPosts)-10:]
	}
	// Reverse to show newest first
	for i, j := 0, len(recentPosts)-1; i < j; i, j = i+1, j-1 {
		recentPosts[i], recentPosts[j] = recentPosts[j], recentPosts[i]
	}

	postLinksHTML := ""
	if len(recentPosts) > 0 {
		postLinksHTML = "<h2>Recent Posts</h2>\n\t<ul>\n"
		for _, post := range recentPosts {
			postURL := strings.ReplaceAll(post.Title, " ", "_")
			postLinksHTML += fmt.Sprintf("\t\t<li><a href=\"/%s\">%s</a></li>\n", postURL, post.Title)
		}
		postLinksHTML += "\t</ul>"
	}

	html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
	<title>Blog</title>
</head>
<body>
	<h1>Welcome to the blog</h1>
	%s
</body>
</html>`, postLinksHTML)
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

func postHandler(w http.ResponseWriter, r *http.Request) {
	// Extract the post title from the URL path
	// Remove leading "/" and convert underscores to spaces
	postTitle := strings.TrimPrefix(r.URL.Path, "/")
	postTitle = strings.ReplaceAll(postTitle, "_", " ")

	// Find the post with the matching title
	var foundPost *Post
	for i := range posts {
		if posts[i].Title == postTitle {
			foundPost = &posts[i]
			break
		}
	}

	if foundPost == nil {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprint(w, "Post not found")
		return
	}

	html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
	<title>%s</title>
</head>
<body>
	<h1>%s</h1>
	<p>%s</p>
</body>
</html>`, foundPost.Title, foundPost.Title, foundPost.Body)
	w.Header().Set("Content-Type", "text/html")
	fmt.Fprint(w, html)
}

func main() {
	// Create a custom router
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			welcomeHandler(w, r)
		} else if r.URL.Path == "/new" {
			newPostHandler(w, r)
		} else {
			postHandler(w, r)
		}
	})

	fmt.Println("Server running on http://localhost:8080")
	http.ListenAndServe(":8080", nil)
}
