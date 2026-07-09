# Blog

A simple Sinatra + SQLite blog. Create posts and view them locally in your browser.

## Prerequisites

- **Ruby 2.6.x** (developed against 2.6.10)
- **Bundler** (`gem install bundler` if it is not already available)

## Install

Install the gem dependencies:

```sh
bundle install
```

## Run

Start the local webserver:

```sh
bundle exec rackup
```

Then open <http://localhost:9292> in your browser.

## Test

Run the test suite:

```sh
bundle exec rake test
```

## Routes

- `/` — welcome home page with a "Recent Posts" list of the 10 newest posts.
- `/new` — form to create a new post (submits to `POST /`, which redirects to the new post).
- `/:post_title` — view a single post; underscores in the URL map to spaces in the title (e.g. `/test_post` → "test post").
