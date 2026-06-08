use std::sync::{Arc, Mutex};

use axum::{
    extract::State,
    response::{Html, IntoResponse, Redirect},
    routing::get,
    Form, Router,
};
use rusqlite::Connection;
use serde::Deserialize;

pub mod db;

#[derive(Clone)]
pub struct AppState {
    pub conn: Arc<Mutex<Connection>>,
}

pub fn app() -> Router {
    let conn = db::open_in_memory().expect("failed to open db");
    app_with_conn(conn)
}

pub fn app_with_conn(conn: Connection) -> Router {
    let state = AppState {
        conn: Arc::new(Mutex::new(conn)),
    };
    Router::new()
        .route("/", get(root))
        .route("/new", get(new_post_form).post(create_post_handler))
        .with_state(state)
}

async fn root() -> &'static str {
    "Welcome to the blog"
}

async fn new_post_form() -> Html<&'static str> {
    Html(
        r#"<!DOCTYPE html>
<html>
<head><title>New Post</title></head>
<body>
<h1>New Post</h1>
<form method="post" action="/new">
  <label>Title: <input type="text" name="title" /></label><br />
  <label>Body: <textarea name="body"></textarea></label><br />
  <button type="submit">Create Post</button>
</form>
</body>
</html>"#,
    )
}

#[derive(Deserialize)]
struct NewPost {
    title: String,
    body: String,
}

async fn create_post_handler(
    State(state): State<AppState>,
    Form(input): Form<NewPost>,
) -> impl IntoResponse {
    {
        let conn = state.conn.lock().expect("db lock poisoned");
        db::create_post(&conn, &input.title, &input.body).expect("failed to persist post");
    }
    Redirect::to("/")
}
