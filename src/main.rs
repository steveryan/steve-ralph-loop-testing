use tokio::net::TcpListener;

#[tokio::main]
async fn main() {
    let listener = TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("failed to bind to address");
    println!("listening on http://{}", listener.local_addr().unwrap());
    let conn = blog::db::open("blog.db").expect("failed to open database");
    axum::serve(listener, blog::app_with_conn(conn))
        .await
        .expect("server error");
}
