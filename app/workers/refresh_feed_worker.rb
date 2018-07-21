class RefreshFeedWorker
  include Sidekiq::Worker

  def perform(feed_id)
    feed = Feed[feed_id]
    puts "Pulling feed at #{feed.url}"
    feed.update refreshed_at: Time.now
  end
end
