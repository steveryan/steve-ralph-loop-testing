package main

import (
	"fmt"
	"net/http"
)

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

func main() {
	http.HandleFunc("/", welcomeHandler)

	fmt.Println("Server running on http://localhost:8080")
	http.ListenAndServe(":8080", nil)
}
