use blog::db;
use std::collections::HashMap;
use tokio::net::TcpListener;

#[tokio::test]
async fn webserver_is_available() {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app()).await.unwrap();
    });

    let url = format!("http://{}/", addr);
    let resp = reqwest::get(&url).await.expect("request failed");
    assert!(resp.status().is_success());
}

#[tokio::test]
async fn home_page_shows_welcome() {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app()).await.unwrap();
    });

    let url = format!("http://{}/", addr);
    let resp = reqwest::get(&url).await.expect("request failed");
    assert!(resp.status().is_success());
    let body = resp.text().await.expect("failed to read body");
    assert!(body.contains("Welcome to the blog"));
}

fn temp_db_path(slug: &str) -> std::path::PathBuf {
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    std::env::temp_dir().join(format!("blog_test_{}_{}.sqlite", slug, nanos))
}

#[tokio::test]
async fn new_post_page_is_reachable_and_has_form() {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app()).await.unwrap();
    });

    let url = format!("http://{}/new", addr);
    let resp = reqwest::get(&url).await.expect("request failed");
    assert!(resp.status().is_success());
    let body = resp.text().await.expect("failed to read body");

    assert!(body.contains("<form"));
    assert!(body.contains(r#"method="post""#));
    assert!(body.contains(r#"action="/new""#));
    assert!(body.contains(r#"name="title""#));
    assert!(body.contains(r#"name="body""#));
    assert!(body.contains("type=\"submit\"") || body.contains("<button"));
}

#[tokio::test]
async fn new_post_form_submission_persists_post() {
    let db_path = temp_db_path("new_post");
    let path_str = db_path.to_str().unwrap().to_string();

    let conn = db::open(&path_str).expect("failed to open db");
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app_with_conn(conn)).await.unwrap();
    });

    let url = format!("http://{}/new", addr);
    let mut form = HashMap::new();
    form.insert("title", "Persisted Title");
    form.insert("body", "Persisted Body");

    let client = reqwest::Client::new();
    let resp = client
        .post(&url)
        .form(&form)
        .send()
        .await
        .expect("post request failed");
    assert!(resp.status().is_success() || resp.status().is_redirection());

    let verify_conn = db::open(&path_str).expect("failed to reopen db");
    let (title, body) = {
        let mut stmt = verify_conn
            .prepare("SELECT title, body FROM posts WHERE title = ?1")
            .unwrap();
        let mut rows = stmt
            .query_map(["Persisted Title"], |row| {
                Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
            })
            .unwrap();
        rows.next()
            .expect("post should be persisted")
            .expect("row read failed")
    };
    assert_eq!(title, "Persisted Title");
    assert_eq!(body, "Persisted Body");

    drop(verify_conn);
    let _ = std::fs::remove_file(&db_path);
}

#[tokio::test]
async fn show_post_displays_matching_post() {
    let db_path = temp_db_path("show_post");
    let path_str = db_path.to_str().unwrap().to_string();

    let conn = db::open(&path_str).expect("failed to open db");
    db::create_post(&conn, "test post", "This is the test post body")
        .expect("failed to create post");

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app_with_conn(conn)).await.unwrap();
    });

    let url = format!("http://{}/test_post", addr);
    let resp = reqwest::get(&url).await.expect("request failed");
    assert!(resp.status().is_success());
    let body = resp.text().await.expect("failed to read body");
    assert!(body.contains("test post"));
    assert!(body.contains("This is the test post body"));

    let _ = std::fs::remove_file(&db_path);
}
