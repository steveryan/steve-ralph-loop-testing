require 'sinatra'
require_relative 'post'

get '/' do
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head><title>Blog</title></head>
      <body>
        <h1>Welcome to the blog</h1>
      </body>
    </html>
  HTML
end
