use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::SqlitePool;

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct Tweet {
    pub id: i64,
    pub author_name: String,
    pub body: String,
    pub created: chrono::NaiveDateTime,
}

/// Open (creating if needed) a SQLite pool at `path` and ensure the schema exists.
pub async fn init_pool(path: &str) -> Result<SqlitePool, sqlx::Error> {
    let options = SqliteConnectOptions::new()
        .filename(path)
        .create_if_missing(true);
    let pool = SqlitePoolOptions::new().connect_with(options).await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS tweets (\
            id INTEGER PRIMARY KEY AUTOINCREMENT, \
            author_name TEXT NOT NULL, \
            body TEXT NOT NULL, \
            created TEXT NOT NULL DEFAULT (datetime('now'))\
        )",
    )
    .execute(&pool)
    .await?;

    Ok(pool)
}

/// Insert a new tweet. `created` is populated by the database default.
pub async fn insert_tweet(
    pool: &SqlitePool,
    author_name: &str,
    body: &str,
) -> Result<(), sqlx::Error> {
    sqlx::query("INSERT INTO tweets (author_name, body) VALUES (?, ?)")
        .bind(author_name)
        .bind(body)
        .execute(pool)
        .await?;
    Ok(())
}

/// List all tweets ordered most-to-least recent.
pub async fn list_tweets(pool: &SqlitePool) -> Result<Vec<Tweet>, sqlx::Error> {
    let tweets = sqlx::query_as::<_, Tweet>(
        "SELECT id, author_name, body, created FROM tweets ORDER BY created DESC, id DESC",
    )
    .fetch_all(pool)
    .await?;
    Ok(tweets)
}
