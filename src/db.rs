use rusqlite::{params, Connection, Result, Row};

#[derive(Debug, Clone)]
pub struct Post {
    pub id: i64,
    pub title: String,
    pub body: String,
    pub created_at: String,
}

fn row_to_post(row: &Row) -> Result<Post> {
    Ok(Post {
        id: row.get(0)?,
        title: row.get(1)?,
        body: row.get(2)?,
        created_at: row.get(3)?,
    })
}

pub fn init_db(conn: &Connection) -> Result<()> {
    conn.execute(
        "CREATE TABLE IF NOT EXISTS posts (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now')))",
        [],
    )?;
    Ok(())
}

pub fn insert_post(conn: &Connection, title: &str, body: &str) -> Result<Post> {
    conn.execute(
        "INSERT INTO posts (title, body) VALUES (?1, ?2)",
        params![title, body],
    )?;
    let id = conn.last_insert_rowid();
    conn.query_row(
        "SELECT id, title, body, created_at FROM posts WHERE id = ?1",
        params![id],
        row_to_post,
    )
}

pub fn list_posts(conn: &Connection) -> Result<Vec<Post>> {
    let mut stmt =
        conn.prepare("SELECT id, title, body, created_at FROM posts ORDER BY id DESC")?;
    let rows = stmt.query_map([], row_to_post)?;
    rows.collect()
}

pub fn get_post(conn: &Connection, id: i64) -> Result<Option<Post>> {
    let mut stmt = conn.prepare("SELECT id, title, body, created_at FROM posts WHERE id = ?1")?;
    match stmt.query_row(params![id], row_to_post) {
        Ok(post) => Ok(Some(post)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn list_posts_returns_both_newest_first() {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();

        let first = insert_post(&conn, "First", "First body").unwrap();
        let second = insert_post(&conn, "Second", "Second body").unwrap();

        let posts = list_posts(&conn).unwrap();
        assert_eq!(posts.len(), 2);
        assert_eq!(posts[0].id, second.id);
        assert_eq!(posts[0].title, "Second");
        assert_eq!(posts[1].id, first.id);
        assert_eq!(posts[1].title, "First");
    }

    #[test]
    fn get_post_round_trips_and_handles_missing() {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();

        let created = insert_post(&conn, "Hello", "World body").unwrap();

        let fetched = get_post(&conn, created.id).unwrap().unwrap();
        assert_eq!(fetched.id, created.id);
        assert_eq!(fetched.title, "Hello");
        assert_eq!(fetched.body, "World body");
        assert!(!fetched.created_at.is_empty());

        assert!(get_post(&conn, 9999).unwrap().is_none());
    }
}
