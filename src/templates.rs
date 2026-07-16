use askama::Template;

use crate::db::Tweet;

#[derive(Template)]
#[template(path = "index.html")]
pub struct IndexTemplate {
    pub tweets: Vec<Tweet>,
}

#[derive(Template)]
#[template(path = "new.html")]
pub struct NewTemplate;
