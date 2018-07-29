require 'feed_downloader'

class RefreshFeedWorker
  include Sidekiq::Worker

  attr_reader :feed

  def perform(feed_id)
    @feed = Feed[feed_id]
    feed_posts.each do |post|
      import_post post
    end
    feed.update refreshed_at: Time.now
  end

  private

  def feed_posts
    @feed_posts ||= begin
                      posts = FeedDownloader.new(feed.url).posts
                      posts.each do |post|
                        post.feed_id = feed.id
                      end
                      posts
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
end
