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
