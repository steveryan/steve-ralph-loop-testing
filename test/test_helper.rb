ENV['RACK_ENV'] = 'test'
ENV['BLOG_DB'] = 'db/test.sqlite3'

require 'minitest/autorun'
require 'rack/test'
require_relative '../app'

class BlogTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    db = ENV['BLOG_DB']
    File.delete(db) if db && File.exist?(db)
  end
end
