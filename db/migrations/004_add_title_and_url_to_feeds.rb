Sequel.migration do
  change do
    alter_table :feeds do
      add_column :title, String, null: false, default: ''
      add_column :homepage_url, String, null: false, default: ''
    end
  end
end
