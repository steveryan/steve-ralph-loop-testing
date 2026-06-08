use axum::{routing::get, Router};

pub mod db;

pub fn app() -> Router {
    Router::new().route("/", get(root))
}

async fn root() -> &'static str {
    "Welcome to the blog"
}
