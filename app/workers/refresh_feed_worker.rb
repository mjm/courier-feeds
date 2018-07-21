require 'feed_downloader'

class RefreshFeedWorker
  include Sidekiq::Worker

  def perform(feed_id)
    feed = Feed[feed_id]
    downloader = FeedDownloader.new(feed.url)
    downloader.posts.each do |post|
      p post
    end
    feed.update refreshed_at: Time.now
  end
end
