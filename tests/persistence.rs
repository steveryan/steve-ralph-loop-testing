// Integration tests for the persistence layer (src/db.rs).
//
// The crate is now split into a library (`twitter_clone`) plus a thin binary,
// so the `db` module is imported normally instead of textually re-included.
// Each test runs against a throwaway SQLite database in the system temp
// directory (see `common::TempDb`), so the tests never touch `tweets.db`.

mod common;

use common::TempDb;
use twitter_clone::db;

#[tokio::test]
async fn insert_then_list_returns_inserted_tweet() {
    let tmp = TempDb::new();
    let pool = db::init_pool(tmp.path_str()).await.expect("init pool");

    db::insert_tweet(&pool, "alice", "hello world")
        .await
        .expect("insert tweet");

    let tweets = db::list_tweets(&pool).await.expect("list tweets");

    assert_eq!(tweets.len(), 1, "exactly one tweet should be persisted");
    assert_eq!(tweets[0].author_name, "alice");
    assert_eq!(tweets[0].body, "hello world");

    pool.close().await;
}

#[tokio::test]
async fn multiple_tweets_ordered_most_to_least_recent() {
    let tmp = TempDb::new();
    let pool = db::init_pool(tmp.path_str()).await.expect("init pool");

    // Insert in chronological order; the newest insert must come back first.
    for (author, body) in [
        ("alice", "first"),
        ("bob", "second"),
        ("carol", "third"),
    ] {
        db::insert_tweet(&pool, author, body)
            .await
            .expect("insert tweet");
    }

    let tweets = db::list_tweets(&pool).await.expect("list tweets");

    let bodies: Vec<&str> = tweets.iter().map(|t| t.body.as_str()).collect();
    assert_eq!(
        bodies,
        vec!["third", "second", "first"],
        "tweets should be ordered most-to-least recent"
    );

    // Ids increase with insertion order, so newest-first also means id-descending.
    assert!(
        tweets.windows(2).all(|w| w[0].id > w[1].id),
        "ids should be strictly descending (newest first)"
    );

    // `created` timestamps must be non-increasing down the newest-first list.
    assert!(
        tweets.windows(2).all(|w| w[0].created >= w[1].created),
        "created timestamps should be non-increasing (newest first)"
    );

    pool.close().await;
}
