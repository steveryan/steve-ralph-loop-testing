use tokio::net::TcpListener;

#[tokio::main]
async fn main() {
    let listener = TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("failed to bind to address");
    println!("listening on http://{}", listener.local_addr().unwrap());
    axum::serve(listener, blog::app())
        .await
        .expect("server error");
}
