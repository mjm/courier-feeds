class Feed < Sequel::Model(DB[:feeds])
  plugin :timestamps, update_on_create: true

  one_to_many :user_feeds

  dataset_module do
    def by_user(user_id)
      # TODO is there a more succinct way to express this in Sequel?
      # I guess there would be if we had a User model but we don't
      where(id: DB[:user_feeds].where(user_id: user_id).select(:feed_id))
    end
  end

  def user_ids
    user_feeds_dataset.order(:user_id).select_map(:user_id)
  end

  def add_user_id(user_id)
    add_user_feed(user_id: user_id)
  end

  def refresh
    RefreshFeedWorker.perform_async(id)
  end

  def self.register(attrs)
    attrs = attrs.transform_keys(&:to_sym)
    user_id = attrs.delete(:user_id)
    feed = find_or_create(attrs)
    feed.add_user_id(user_id) if user_id
    feed
  end
end
