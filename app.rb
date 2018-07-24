require 'config/environment'

class FeedsHandler
  def get_feeds(_req, _env)
    { feeds: Feed.all.map(&:to_proto) }
  end

  def get_user_feeds(req, _env)
    feeds = Feed.by_user(req.user_id).all
    { feeds: feeds.map(&:to_proto) }
  end

  def register_feed(req, _env)
    feed = Feed.register(req.to_hash)
    feed.to_proto
  rescue Sequel::UniqueConstraintViolation
    Twirp::Error.already_exists 'The user is already registered to this feed.'
  end

  def refresh_feed(req, _env)
    feed = Feed[req.feed_id]
    if feed
      job_id = feed.refresh!
      { status: 'refreshing', job_id: job_id }
    else
      Twirp::Error.not_found 'There is no feed with the given ID.'
    end
  end
end

class DocHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless doc_request?(env)
    [200, { 'Content-Type' => 'text/html' },
     [File.read(File.join(__dir__, 'doc', 'index.html'))]]
  end

  def doc_request?(env)
    env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] =~ %r{^/?$}
  end
end

App = Courier::FeedsService.new(FeedsHandler.new)
