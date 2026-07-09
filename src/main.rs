use axum::{routing::get, Router};

mod db;

type Db = std::sync::Arc<std::sync::Mutex<rusqlite::Connection>>;

fn app(db: Db) -> Router {
    Router::new().route("/", get(index)).with_state(db)
}

#[tokio::main]
async fn main() {
    let conn = rusqlite::Connection::open("blog.db").unwrap();
    db::init_db(&conn).unwrap();
    let db: Db = std::sync::Arc::new(std::sync::Mutex::new(conn));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    axum::serve(listener, app(db)).await.unwrap();
}

async fn index() -> &'static str {
    "blog"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trivial() {
        assert_eq!(2 + 2, 4);
    }

    #[test]
    fn app_builds() {
        let conn = rusqlite::Connection::open_in_memory().unwrap();
        db::init_db(&conn).unwrap();
        let db: Db = std::sync::Arc::new(std::sync::Mutex::new(conn));
        let _router = app(db);
    }
}
