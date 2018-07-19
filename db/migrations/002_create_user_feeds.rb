Sequel.migration do
  change do
    create_table :user_feeds do
      foreign_key :feed_id, :feeds, on_delete: :cascade, null: false
      Integer :user_id, null: false
      primary_key %i[feed_id user_id]
      index %i[feed_id user_id]
    end
  end
end
