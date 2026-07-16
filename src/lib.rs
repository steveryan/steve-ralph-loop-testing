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

/// Maximum accepted length (in characters) for a tweet author's name.
pub const MAX_AUTHOR_NAME_LEN: usize = 50;
/// Maximum accepted length (in characters) for a tweet body.
pub const MAX_BODY_LEN: usize = 280;

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
    let tweets = db::list_tweets(&pool).await.map_err(|e| {
        eprintln!("error: failed to load tweets for homepage: {e}");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
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

/// Persist a submitted tweet, then redirect home.
///
/// Invalid input (empty or over-length fields) is rejected by redirecting back
/// to the form without inserting. A genuine persistence failure is surfaced as
/// a 500 and logged, so it is never silently swallowed or mistaken for an
/// ordinary validation redirect.
async fn create_tweet(
    State(pool): State<SqlitePool>,
    Form(form): Form<NewTweetForm>,
) -> Result<Redirect, StatusCode> {
    let author_name = form.author_name.trim();
    let body = form.body.trim();
    if author_name.is_empty()
        || body.is_empty()
        || author_name.chars().count() > MAX_AUTHOR_NAME_LEN
        || body.chars().count() > MAX_BODY_LEN
    {
        return Ok(Redirect::to("/new"));
    }
    db::insert_tweet(&pool, author_name, body).await.map_err(|e| {
        eprintln!("error: failed to persist tweet: {e}");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    Ok(Redirect::to("/"))
}
