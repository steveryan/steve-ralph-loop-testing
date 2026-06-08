use blog::db;

#[test]
fn posts_table_stores_title_and_body() {
    let conn = db::open_in_memory().expect("failed to open db");

    let id = db::create_post(&conn, "My First Post", "Hello, world!")
        .expect("failed to insert post");

    let post = db::get_post(&conn, id)
        .expect("query failed")
        .expect("post should exist");

    assert_eq!(post.id, id);
    assert_eq!(post.title, "My First Post");
    assert_eq!(post.body, "Hello, world!");
}
