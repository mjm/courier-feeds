require 'feed_downloader'

class RefreshFeedWorker
  include Sidekiq::Worker

  attr_reader :feed

  def perform(feed_id)
    @feed = Feed[feed_id]
    feed_posts.each do |post|
      import_post post
    end
    update_feed
  end

  private

  def downloaded_feed
    @downloaded_feed ||= feed_downloader.feed
  end

  def feed_downloader
    FeedDownloader.new(feed.url,
                       etag: feed.etag,
                       last_modified: feed.last_modified_at,
                       logger: logger)
  end

  def feed_posts
    @feed_posts ||= (downloaded_feed&.posts || []).each do |post|
      post.feed_id = feed.id
    end
  end

  def import_post(post)
    feed.user_ids.each do |user_id|
      import_post_for_user post, user_id
    end
  end

  def import_post_for_user(post, user_id)
    posts_client.import_post(user_id: user_id, post: post)
  end

  def posts_client
    @posts_client ||= Courier::PostsClient.connect(
      token: Courier::Service::TOKEN
    )
  end

  def update_feed
    feed.refreshed_at = Time.now
    if downloaded_feed
      feed.etag = downloaded_feed.etag
      feed.last_modified_at = downloaded_feed.last_modified
    end
    feed.save
  end
end
