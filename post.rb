require 'sqlite3'
require 'fileutils'

module Post
  DEFAULT_DB = 'db/blog.sqlite3'.freeze

  def self.db_path
    ENV['BLOG_DB'] || DEFAULT_DB
  end

  def self.connect
    path = db_path
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless dir.empty? || dir == '.' || Dir.exist?(dir)

    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    db.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    SQL
    db
  end

  def self.with_db
    db = connect
    yield db
  ensure
    db.close if db
  end

  def self.setup!
    with_db { |_db| true }
  end

  def self.create(title:, body:)
    with_db do |db|
      db.execute(
        'INSERT INTO posts (title, body, created_at) VALUES (?, ?, ?)',
        [title, body, Time.now.to_i]
      )
      fetch_by_id(db, db.last_insert_row_id)
    end
  end

  def self.all
    with_db do |db|
      db.execute('SELECT id, title, body, created_at FROM posts ORDER BY id DESC')
    end
  end

  def self.find_by_title(title)
    with_db do |db|
      db.execute(
        'SELECT id, title, body, created_at FROM posts WHERE title = ? ORDER BY id DESC LIMIT 1',
        [title]
      ).first
    end
  end

  def self.fetch_by_id(db, id)
    db.execute(
      'SELECT id, title, body, created_at FROM posts WHERE id = ? LIMIT 1',
      [id]
    ).first
  end
  private_class_method :fetch_by_id
end

Post.setup!
