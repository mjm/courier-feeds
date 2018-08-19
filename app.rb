require 'config/environment'

class FeedsHandler
  include Courier::Authorization

  def get_feeds(_req, env)
    require_token env do
      { feeds: Feed.all.map(&:to_proto) }
    end
  end

  def get_user_feeds(req, env)
    require_user env, id: req.user_id do
      feeds = Feed.by_user(req.user_id).all
      { feeds: feeds.map(&:to_proto) }
    end
  end

  def register_feed(req, env)
    require_user env, id: req.user_id do
      feed = Feed.register(req.to_hash)
      feed.to_proto
    rescue Sequel::UniqueConstraintViolation
      Twirp::Error.already_exists 'The user is already registered to this feed.'
    end
  end

  def refresh_feed(req, env)
    require_token env do
      feed = Feed[req.feed_id]
      if feed
        job_id = feed.refresh!
        { status: 'refreshing', job_id: job_id }
      else
        Twirp::Error.not_found 'There is no feed with the given ID.'
      end
    end
  end

  def ping(req, _env)
    feeds = Feed.by_home_page_url(req.url).to_a
    feeds.each(&:refresh!)

    { feeds: feeds.map(&:to_proto) }
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

App.before do |rack_env, env|
  env[:token] = rack_env['jwt.token']
end
