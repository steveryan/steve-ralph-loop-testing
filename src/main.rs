use axum::{routing::get, Router};

mod db;

#[tokio::main]
async fn main() {
    let pool = db::init_pool("tweets.db")
        .await
        .expect("failed to initialize database");

    let app = Router::new().route("/", get(root)).with_state(pool);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("failed to bind to 127.0.0.1:3000");
    println!("listening on http://127.0.0.1:3000");
    axum::serve(listener, app)
        .await
        .expect("server error");
}

async fn root() -> &'static str {
    "ok"
}
