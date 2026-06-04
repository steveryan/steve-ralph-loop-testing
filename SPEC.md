# Ralph Loop Spec

Create a basic Blog in Go. I should be able to start a local server, navigate to it in my browser, view a list of posts, create a new post, etc. 

This does not need to have authentication or logins.
You may store data such as the text content of the posts in memory, or files in this folder.

## Conventions

- One task per `- [ ]` line at the top level of "## Tasks".
- The agent will only change `- [ ]` -> `- [x]` on the line it just finished.
- If a task is blocked, the agent appends ` <!-- blocked: ... -->` to it
  and the loop stops; edit the spec to clarify, then re-run.

## Tasks

- [ ] Create the basic go app that runs a local webserver
- [ ] Create a test that the webserver is able to be accessed
- [ ] Create a welcome page that is the home page of the blog. For now it should just say "Welcome to the blog"
- [ ] Create a test that the webserver shows the welcome page by default
- [ ] Create a new post page located at /new that contains a form allowing the user to enter a title and body text. When the user submits the form it should persist the post.
- [ ] Create a test that verifies this page is reachable and contains the right elements. Assert that when submited the post is persisted
- [ ] Create a route /:post_title that finds and displays the post with a matching title (substitute "_"s in the url for spaces in the post title)
- [ ] Create a test that creates a post with the title "test post", navigate to /test_post and assert that the proper post is shown
