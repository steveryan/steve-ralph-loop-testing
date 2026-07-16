// Shared test helpers for the integration test crates.

use std::path::PathBuf;
use std::sync::atomic::{AtomicU32, Ordering};

static COUNTER: AtomicU32 = AtomicU32::new(0);

/// A unique, self-cleaning SQLite database file in the system temp directory,
/// so tests never touch the on-disk `tweets.db`.
pub struct TempDb {
    path: PathBuf,
}

impl TempDb {
    pub fn new() -> Self {
        let n = COUNTER.fetch_add(1, Ordering::SeqCst);
        let mut path = std::env::temp_dir();
        path.push(format!("twitter_clone_test_{}_{}.db", std::process::id(), n));
        let tmp = TempDb { path };
        tmp.remove_files();
        tmp
    }

    pub fn path_str(&self) -> &str {
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
