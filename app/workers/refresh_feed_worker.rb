class RefreshFeedWorker
  include Sidekiq::Worker

  def perform(feed_id)
    puts "Refreshing feed #{feed_id}"
  end
end
