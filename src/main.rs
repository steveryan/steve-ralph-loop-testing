use twitter_clone::{build_app, db};

#[tokio::main]
async fn main() {
    let pool = db::init_pool("tweets.db")
        .await
        .expect("failed to initialize database");

    let app = build_app(pool);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("failed to bind to 127.0.0.1:3000");
    println!("listening on http://127.0.0.1:3000");
    axum::serve(listener, app)
        .await
        .expect("server error");
}
