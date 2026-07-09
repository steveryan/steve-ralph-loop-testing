use axum::{
    extract::{Form, Path, State},
    http::StatusCode,
    response::{Html, Redirect},
    routing::{get, post},
    Router,
};
use serde::Deserialize;

mod db;

type Db = std::sync::Arc<std::sync::Mutex<rusqlite::Connection>>;

fn app(db: Db) -> Router {
    Router::new()
        .route("/", get(index))
        .route("/posts/new", get(new_post_form))
        .route("/posts", post(create_post))
        .route("/posts/{id}", get(show_post))
        .with_state(db)
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

async fn index(State(db): State<Db>) -> Html<String> {
    let posts = {
        let conn = db.lock().unwrap();
        db::list_posts(&conn).unwrap()
    };

    let content = if posts.is_empty() {
        "<p>No posts yet</p>".to_string()
    } else {
        let items: String = posts
            .iter()
            .map(|p| format!("<li><a href=\"/posts/{}\">{}</a></li>", p.id, p.title))
            .collect();
        format!("<ul>{}</ul>", items)
    };

    Html(format!(
        "<!DOCTYPE html><html><head><title>blog</title></head><body><h1>blog</h1><p><a href=\"/posts/new\">New post</a></p>{}</body></html>",
        content
    ))
}

async fn show_post(
    State(db): State<Db>,
    Path(id): Path<i64>,
) -> Result<Html<String>, StatusCode> {
    let post = {
        let conn = db.lock().unwrap();
        db::get_post(&conn, id).unwrap()
    };

    match post {
        Some(post) => Ok(Html(format!(
            "<!DOCTYPE html><html><head><title>{}</title></head><body><h1>{}</h1><p>{}</p><p><a href=\"/\">Back</a></p></body></html>",
            post.title, post.title, post.body
        ))),
        None => Err(StatusCode::NOT_FOUND),
    }
}

#[derive(Deserialize)]
struct NewPost {
    title: String,
    body: String,
}

async fn new_post_form() -> Html<String> {
    Html(
        "<!DOCTYPE html><html><head><title>New post</title></head><body><h1>New post</h1>\
         <form method=\"post\" action=\"/posts\">\
         <p><label>Title <input type=\"text\" name=\"title\"></label></p>\
         <p><label>Body <textarea name=\"body\"></textarea></label></p>\
         <p><button type=\"submit\">Create</button></p>\
         </form><p><a href=\"/\">Back</a></p></body></html>"
            .to_string(),
    )
}

async fn create_post(State(db): State<Db>, Form(new_post): Form<NewPost>) -> Redirect {
    let post = {
        let conn = db.lock().unwrap();
        db::insert_post(&conn, &new_post.title, &new_post.body).unwrap()
    };
    Redirect::to(&format!("/posts/{}", post.id))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::{to_bytes, Body};
    use axum::http::Request;
    use tower::ServiceExt;

    fn seeded_db() -> (Db, i64) {
        let conn = rusqlite::Connection::open_in_memory().unwrap();
        db::init_db(&conn).unwrap();
        let post = db::insert_post(&conn, "Seeded Title", "Seeded body content").unwrap();
        let db: Db = std::sync::Arc::new(std::sync::Mutex::new(conn));
        (db, post.id)
    }

    async fn body_string(response: axum::response::Response) -> String {
        let bytes = to_bytes(response.into_body(), usize::MAX).await.unwrap();
        String::from_utf8(bytes.to_vec()).unwrap()
    }

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

    #[tokio::test]
    async fn index_lists_posts() {
        let (db, _id) = seeded_db();
        let response = app(db)
            .oneshot(Request::builder().uri("/").body(Body::empty()).unwrap())
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let body = body_string(response).await;
        assert!(body.contains("Seeded Title"));
    }

    #[tokio::test]
    async fn show_post_contains_body() {
        let (db, id) = seeded_db();
        let response = app(db)
            .oneshot(
                Request::builder()
                    .uri(format!("/posts/{}", id))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let body = body_string(response).await;
        assert!(body.contains("Seeded body content"));
    }

    #[tokio::test]
    async fn show_missing_post_returns_404() {
        let (db, _id) = seeded_db();
        let response = app(db)
            .oneshot(
                Request::builder()
                    .uri("/posts/9999")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::NOT_FOUND);
    }

    #[tokio::test]
    async fn create_post_redirects_and_persists() {
        let (db, _id) = seeded_db();
        let response = app(db.clone())
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/posts")
                    .header("content-type", "application/x-www-form-urlencoded")
                    .body(Body::from("title=New+Title&body=New+body+content"))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert!(response.status().is_redirection());

        let posts = {
            let conn = db.lock().unwrap();
            db::list_posts(&conn).unwrap()
        };
        assert!(posts
            .iter()
            .any(|p| p.title == "New Title" && p.body == "New body content"));
    }

    #[tokio::test]
    async fn new_post_form_renders() {
        let (db, _id) = seeded_db();
        let response = app(db)
            .oneshot(
                Request::builder()
                    .uri("/posts/new")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let body = body_string(response).await;
        assert!(body.contains("<form"));
        assert!(body.contains("name=\"title\""));
        assert!(body.contains("name=\"body\""));
    }
}
