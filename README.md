# Blog

A very simple blog built with [Elixir](https://elixir-lang.org/) and the
[Phoenix](https://www.phoenixframework.org/) framework. It lets you create,
edit, and delete posts, persists them to disk, and gives every post a direct,
shareable link.

- **Storage:** posts are persisted in a local **SQLite** database
  (`blog_dev.db`) via [`ecto_sqlite3`](https://hex.pm/packages/ecto_sqlite3).
  There is no separate database server to install or start.
- **No accounts, no authentication:** the blog is intentionally open — there is
  no login, signup, or user management. Anyone with access to the running app
  can manage posts.
- **Landing page:** opening the app at `/` lands on the list of posts.
- **Direct links:** each post is directly linkable at `/posts/:id`.

## Running the blog locally

1. Install dependencies and set up the database (this also loads a few sample
   posts via the seeds):

   ```sh
   mix setup
   ```

2. Start the web server:

   ```sh
   mix phx.server
   ```

   Or start it inside an IEx session with `iex -S mix phx.server`.

3. Open [`http://localhost:4000`](http://localhost:4000) in your browser. You
   will land on the list of posts, where you can create new ones and follow the
   link to any individual post at `/posts/:id`.

To run the test suite, use `mix test`.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
