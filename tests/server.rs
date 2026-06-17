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

#[tokio::test]
async fn toolbar_appears_on_every_page() {
    let db_path = temp_db_path("toolbar");
    let path_str = db_path.to_str().unwrap().to_string();

    let conn = db::open(&path_str).expect("failed to open db");
    db::create_post(&conn, "toolbar post", "Toolbar body").expect("failed to create post");

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app_with_conn(conn)).await.unwrap();
    });

    for path in ["/", "/new", "/toolbar_post"] {
        let url = format!("http://{}{}", addr, path);
        let resp = reqwest::get(&url).await.expect("request failed");
        assert!(resp.status().is_success(), "{} should be reachable", path);
        let body = resp.text().await.expect("failed to read body");

        assert!(
            body.contains(r#"<a href="/new">New Post</a>"#),
            "toolbar New Post button missing on {}",
            path
        );
        assert!(
            body.contains(r#"<a href="/">Home</a>"#),
            "toolbar Home button missing on {}",
            path
        );
    }

    let _ = std::fs::remove_file(&db_path);
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
async fn create_post_redirects_to_post_url() {
    let db_path = temp_db_path("redirect_post");
    let path_str = db_path.to_str().unwrap().to_string();

    let conn = db::open(&path_str).expect("failed to open db");
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app_with_conn(conn)).await.unwrap();
    });

    let url = format!("http://{}/new", addr);
    let mut form = HashMap::new();
    form.insert("title", "Redirect Me");
    form.insert("body", "Redirect Body");

    // Do not follow redirects so we can inspect the Location header.
    let client = reqwest::Client::builder()
        .redirect(reqwest::redirect::Policy::none())
        .build()
        .unwrap();
    let resp = client
        .post(&url)
        .form(&form)
        .send()
        .await
        .expect("post request failed");

    assert!(resp.status().is_redirection(), "expected a redirect response");
    let location = resp
        .headers()
        .get("location")
        .expect("redirect should include Location header")
        .to_str()
        .unwrap();
    assert_eq!(location, "/Redirect_Me");

    // Following the redirect should display the newly created post.
    let follow_url = format!("http://{}{}", addr, location);
    let follow = reqwest::get(&follow_url).await.expect("follow request failed");
    assert!(follow.status().is_success());
    let body = follow.text().await.expect("failed to read body");
    assert!(body.contains("Redirect Me"));
    assert!(body.contains("Redirect Body"));

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

#[tokio::test]
async fn home_page_lists_ten_most_recent_posts() {
    let db_path = temp_db_path("recent_posts");
    let path_str = db_path.to_str().unwrap().to_string();

    let conn = db::open(&path_str).expect("failed to open db");
    for i in 1..=12 {
        db::create_post(&conn, &format!("Post {}", i), &format!("Body {}", i))
            .expect("failed to create post");
    }

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app_with_conn(conn)).await.unwrap();
    });

    let url = format!("http://{}/", addr);
    let resp = reqwest::get(&url).await.expect("request failed");
    assert!(resp.status().is_success());
    let body = resp.text().await.expect("failed to read body");

    assert!(body.contains("Recent Posts"));

    // Ten most recent posts (12 down to 3) should be present.
    for i in 3..=12 {
        assert!(
            body.contains(&format!("Post {}", i)),
            "expected Post {} to be listed",
            i
        );
    }
    // The two oldest (1 and 2) should not appear.
    assert!(!body.contains(">Post 1<"), "Post 1 should not be listed");
    assert!(!body.contains(">Post 2<"), "Post 2 should not be listed");

    // Most recent should appear before the least recent of the ten.
    let pos_newest = body.find("Post 12").expect("Post 12 missing");
    let pos_oldest_shown = body.find("Post 3").expect("Post 3 missing");
    assert!(
        pos_newest < pos_oldest_shown,
        "posts should be ordered most recent first"
    );

    // Links should point to the post url with underscores for spaces.
    assert!(body.contains("/Post_12"), "expected link to /Post_12");

    let _ = std::fs::remove_file(&db_path);
}

#[tokio::test]
async fn pages_include_stylesheet_and_css_is_served() {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, blog::app()).await.unwrap();
    });

    // Every page should link the stylesheet.
    for path in ["/", "/new"] {
        let url = format!("http://{}{}", addr, path);
        let resp = reqwest::get(&url).await.expect("request failed");
        assert!(resp.status().is_success(), "{} should be reachable", path);
        let body = resp.text().await.expect("failed to read body");
        assert!(
            body.contains(r#"<link rel="stylesheet" href="/style.css" />"#),
            "stylesheet link missing on {}",
            path
        );
    }

    // The stylesheet itself should be served as CSS.
    let css_url = format!("http://{}/style.css", addr);
    let resp = reqwest::get(&css_url).await.expect("request failed");
    assert!(resp.status().is_success());
    let content_type = resp
        .headers()
        .get("content-type")
        .expect("missing content-type")
        .to_str()
        .unwrap()
        .to_string();
    assert!(
        content_type.contains("text/css"),
        "expected text/css, got {}",
        content_type
    );
    let css = resp.text().await.expect("failed to read css");
    assert!(css.contains(".toolbar"), "css should style the toolbar");
}
