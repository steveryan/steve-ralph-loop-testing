// Integration tests for the persistence layer (src/db.rs).
//
// `twitter-clone` is a binary crate, so the `db` module isn't exposed as a
// library. We include the source directly with `#[path]` and exercise it
// against a throwaway SQLite database in the system temp directory, so the
// tests never touch the on-disk `tweets.db`.

#[path = "../src/db.rs"]
mod db;

use std::path::PathBuf;
use std::sync::atomic::{AtomicU32, Ordering};

static COUNTER: AtomicU32 = AtomicU32::new(0);

/// A unique, self-cleaning SQLite database file in the system temp directory.
struct TempDb {
    path: PathBuf,
}

impl TempDb {
    fn new() -> Self {
        let n = COUNTER.fetch_add(1, Ordering::SeqCst);
        let mut path = std::env::temp_dir();
        path.push(format!(
            "twitter_clone_test_{}_{}.db",
            std::process::id(),
            n
        ));
        let tmp = TempDb { path };
        tmp.remove_files();
        tmp
    }

    fn path_str(&self) -> &str {
        self.path.to_str().expect("temp path is valid utf-8")
    }

    fn sidecar(&self, suffix: &str) -> PathBuf {
        let mut s = self.path.clone().into_os_string();
        s.push(suffix);
        PathBuf::from(s)
    }

    fn remove_files(&self) {
        // Ignore errors: the files may not exist yet.
        let _ = std::fs::remove_file(&self.path);
        let _ = std::fs::remove_file(self.sidecar("-wal"));
        let _ = std::fs::remove_file(self.sidecar("-shm"));
    }
}

impl Drop for TempDb {
    fn drop(&mut self) {
        self.remove_files();
    }
}

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
