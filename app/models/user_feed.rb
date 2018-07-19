class UserFeed < Sequel::Model(DB[:user_feeds])
  unrestrict_primary_key
  many_to_one :feed
end
