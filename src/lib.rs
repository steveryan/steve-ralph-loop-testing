use axum::{
    extract::State,
    http::StatusCode,
    response::Redirect,
    routing::{get, post},
    Form, Router,
};
use serde::Deserialize;
use sqlx::SqlitePool;

pub mod db;
pub mod templates;

use templates::{IndexTemplate, NewTemplate};

/// Build the application router with the given database pool as shared state.
pub fn build_app(pool: SqlitePool) -> Router {
    Router::new()
        .route("/", get(index))
        .route("/new", get(new_tweet_form))
        .route("/tweets", post(create_tweet))
        .with_state(pool)
}

/// Homepage: render all tweets, most-to-least recent.
async fn index(State(pool): State<SqlitePool>) -> Result<IndexTemplate, StatusCode> {
    let tweets = db::list_tweets(&pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(IndexTemplate { tweets })
}

/// Render the new-tweet form.
async fn new_tweet_form() -> NewTemplate {
    NewTemplate
}

#[derive(Deserialize)]
struct NewTweetForm {
    author_name: String,
    body: String,
}

/// Persist a submitted tweet, then redirect home. Empty fields are rejected
/// by redirecting back to the form without inserting.
async fn create_tweet(
    State(pool): State<SqlitePool>,
    Form(form): Form<NewTweetForm>,
) -> Redirect {
    let author_name = form.author_name.trim();
    let body = form.body.trim();
    if author_name.is_empty() || body.is_empty() {
        return Redirect::to("/new");
    }
    match db::insert_tweet(&pool, author_name, body).await {
        Ok(()) => Redirect::to("/"),
        Err(_) => Redirect::to("/new"),
    }
}
