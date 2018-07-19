class Feed < Sequel::Model(DB[:feeds])
  plugin :timestamps, update_on_create: true

  one_to_many :user_feeds

  def user_ids
    user_feeds_dataset.order(:user_id).select_map(:user_id)
  end

  def add_user_id(user_id)
    add_user_feed(user_id: user_id)
  end

  def self.register(attrs)
    find_or_create(attrs)
  end
end
