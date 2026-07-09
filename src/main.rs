use axum::{routing::get, Router};

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(index));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn index() -> &'static str {
    "blog"
}

#[cfg(test)]
mod tests {
    #[test]
    fn trivial() {
        assert_eq!(2 + 2, 4);
    }
}
