Sequel.migration do
  change do
    alter_table :feeds do
      add_column :etag, String
      add_column :last_modified_at, String
    end
  end
end
