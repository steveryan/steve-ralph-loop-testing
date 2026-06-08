use rusqlite::{Connection, Result};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Post {
    pub id: i64,
    pub title: String,
    pub body: String,
}

pub fn open(path: &str) -> Result<Connection> {
    let conn = Connection::open(path)?;
    init(&conn)?;
    Ok(conn)
}

pub fn open_in_memory() -> Result<Connection> {
    let conn = Connection::open_in_memory()?;
    init(&conn)?;
    Ok(conn)
}

pub fn init(conn: &Connection) -> Result<()> {
    conn.execute(
        "CREATE TABLE IF NOT EXISTS posts (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body  TEXT NOT NULL
        )",
        [],
    )?;
    Ok(())
}

pub fn create_post(conn: &Connection, title: &str, body: &str) -> Result<i64> {
    conn.execute(
        "INSERT INTO posts (title, body) VALUES (?1, ?2)",
        (title, body),
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn get_post_by_title(conn: &Connection, title: &str) -> Result<Option<Post>> {
    let mut stmt = conn.prepare("SELECT id, title, body FROM posts WHERE title = ?1")?;
    let mut rows = stmt.query_map([title], |row| {
        Ok(Post {
            id: row.get(0)?,
            title: row.get(1)?,
            body: row.get(2)?,
        })
    })?;
    match rows.next() {
        Some(post) => Ok(Some(post?)),
        None => Ok(None),
    }
}

pub fn get_post(conn: &Connection, id: i64) -> Result<Option<Post>> {
    let mut stmt = conn.prepare("SELECT id, title, body FROM posts WHERE id = ?1")?;
    let mut rows = stmt.query_map([id], |row| {
        Ok(Post {
            id: row.get(0)?,
            title: row.get(1)?,
            body: row.get(2)?,
        })
    })?;
    match rows.next() {
        Some(post) => Ok(Some(post?)),
        None => Ok(None),
    }
}
