use axum::{routing::get, Router};

pub fn app() -> Router {
    Router::new().route("/", get(root))
}

async fn root() -> &'static str {
    "Blog is running"
}
