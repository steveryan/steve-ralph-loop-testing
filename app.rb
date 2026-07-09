require 'sinatra'
require_relative 'post'

get '/' do
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head><title>Blog</title></head>
      <body>
        <h1>Welcome to the blog</h1>
        <h2>Recent Posts</h2>
        <ul>
    #{recent_posts_list_html}
        </ul>
      </body>
    </html>
  HTML
end

get '/new' do
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head><title>New Post</title></head>
      <body>
        <h1>New Post</h1>
        <form action="/" method="post">
          <p>
            <label>Title<br>
              <input type="text" name="title">
            </label>
          </p>
          <p>
            <label>Body<br>
              <textarea name="body"></textarea>
            </label>
          </p>
          <p>
            <button type="submit">Create Post</button>
          </p>
        </form>
      </body>
    </html>
  HTML
end

post '/' do
  post = Post.create(title: params[:title], body: params[:body])
  slug = post['title'].tr(' ', '_')
  redirect "/#{slug}"
end

get '/:post_title' do
  title = params[:post_title].tr('_', ' ')
  post = Post.find_by_title(title)
  halt 404, not_found_html unless post

  safe_title = Rack::Utils.escape_html(post['title'])
  safe_body = Rack::Utils.escape_html(post['body'])
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head><title>#{safe_title}</title></head>
      <body>
        <h1>#{safe_title}</h1>
        <div>#{safe_body}</div>
      </body>
    </html>
  HTML
end

def recent_posts_list_html
  Post.all.first(10).map do |post|
    title = post['title']
    slug = title.tr(' ', '_')
    %(      <li><a href="/#{Rack::Utils.escape_html(slug)}">#{Rack::Utils.escape_html(title)}</a></li>)
  end.join("\n")
end

def not_found_html
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head><title>Not Found</title></head>
      <body>
        <h1>Post not found</h1>
      </body>
    </html>
  HTML
end
