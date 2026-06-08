# Ralph Loop Spec

Create a basic Blog in Rust. I should be able to start a local server, navigate to it in my browser, view a list of posts, create a new post, etc. 

This does not need to have authentication or logins.
The data should be stored using a local sqlite

## Conventions

- One task per `- [ ]` line at the top level of "## Tasks".
- The agent will only change `- [ ]` -> `- [x]` on the line it just finished.
- If a task is blocked, the agent appends ` <!-- blocked: ... -->` to it
  and the loop stops; edit the spec to clarify, then re-run.

## Tasks

- [x] Create the basic Rust app that runs a local webserver, and create a test that that webserver is available
- [x] Create a welcome page that is the home page of the blog. For now it should just say "Welcome to the blog" and create a test that the webserver shows 
- [x] Create a basic SQLite db that will store the posts. The posts will contain a Title and a Body. Please also write a test that verifies this.
- [x] Create a new post page located at /new that contains a form allowing the user to enter a title and body text. When the user submits the form it should persist the post.
- [x] Create a test that verifies this page is reachable and contains the right elements. Assert that when submited the post is persisted
- [x] Create a route /:post_title that finds and displays the post with a matching title (substitute "_"s in the url for spaces in the post title)
- [x] Create a test that creates a post with the title "test post", navigate to /test_post and assert that the proper post is shown
- [x] Update the home page so it contains a list of links to the ten most recently written posts in the order of most recent to least recent. This should be under a subheading of "Recent Posts". Write a test to confirm this behavior
- [x] When a post is persisted after creation, redirect to that post's url. Write a test to confirm this behavior
- [x] Add toolbar with a button on the homepage to create a new post. It should link to the new post page. Also add a Home button that takes you to the homepage. The toolbar should appear on every page. add a test for this toolbar.