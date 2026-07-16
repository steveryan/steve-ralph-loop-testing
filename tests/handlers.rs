// Handler-level tests for the HTTP routes, exercising the three branches of
// `create_tweet` (invalid -> /new, success -> /, persistence) plus the GET
// routes. Requests are driven through the real router via `oneshot`, against a
// throwaway temp database.

mod common;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use common::TempDb;
use tower::ServiceExt; // for `oneshot`
use twitter_clone::{build_app, db, MAX_BODY_LEN};

fn form_post(uri: &str, body: String) -> Request<Body> {
    Request::builder()
        .method("POST")
        .uri(uri)
        .header("content-type", "application/x-www-form-urlencoded")
        .body(Body::from(body))
        .expect("build request")
}

#[tokio::test]
async fn valid_submission_redirects_home_and_persists() {
    let tmp = TempDb::new();
    let pool = db::init_pool(tmp.path_str()).await.expect("init pool");
    let app = build_app(pool.clone());

    let resp = app
        .oneshot(form_post("/tweets", "author_name=alice&body=hello+world".into()))
        .await
        .expect("response");

    assert_eq!(resp.status(), StatusCode::SEE_OTHER);
    assert_eq!(resp.headers().get("location").unwrap(), "/");

    let tweets = db::list_tweets(&pool).await.expect("list tweets");
    assert_eq!(tweets.len(), 1);
    assert_eq!(tweets[0].author_name, "alice");
    assert_eq!(tweets[0].body, "hello world");

    pool.close().await;
}

#[tokio::test]
async fn empty_field_redirects_to_form_without_persisting() {
    let tmp = TempDb::new();
    let pool = db::init_pool(tmp.path_str()).await.expect("init pool");
    let app = build_app(pool.clone());

    let resp = app
        .oneshot(form_post("/tweets", "author_name=alice&body=".into()))
        .await
        .expect("response");

    assert_eq!(resp.status(), StatusCode::SEE_OTHER);
    assert_eq!(resp.headers().get("location").unwrap(), "/new");

    let tweets = db::list_tweets(&pool).await.expect("list tweets");
    assert!(tweets.is_empty(), "invalid submission must not persist");

    pool.close().await;
}

#[tokio::test]
async fn overlong_body_is_rejected_without_persisting() {
    let tmp = TempDb::new();
    let pool = db::init_pool(tmp.path_str()).await.expect("init pool");
    let app = build_app(pool.clone());

    let long_body = "x".repeat(MAX_BODY_LEN + 1);
    let resp = app
        .oneshot(form_post(
            "/tweets",
            format!("author_name=alice&body={long_body}"),
        ))
        .await
        .expect("response");

    assert_eq!(resp.status(), StatusCode::SEE_OTHER);
    assert_eq!(resp.headers().get("location").unwrap(), "/new");

    let tweets = db::list_tweets(&pool).await.expect("list tweets");
    assert!(tweets.is_empty(), "over-length submission must not persist");

    pool.close().await;
}

#[tokio::test]
async fn get_routes_return_200() {
    let tmp = TempDb::new();
    let pool = db::init_pool(tmp.path_str()).await.expect("init pool");
    let app = build_app(pool.clone());

    let index = app
        .clone()
        .oneshot(Request::builder().uri("/").body(Body::empty()).unwrap())
        .await
        .expect("response");
    assert_eq!(index.status(), StatusCode::OK);

    let new_form = app
        .oneshot(Request::builder().uri("/new").body(Body::empty()).unwrap())
        .await
        .expect("response");
    assert_eq!(new_form.status(), StatusCode::OK);

    pool.close().await;
}
