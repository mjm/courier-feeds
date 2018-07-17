Sequel.migration do
  change do
    create_table :feeds do
      primary_key :id
      String :url, null: false, unique: true
      DateTime :refreshed_at
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
