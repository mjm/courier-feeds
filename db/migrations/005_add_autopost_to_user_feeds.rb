Sequel.migration do
  change do
    alter_table :user_feeds do
      add_column :autopost, TrueClass, null: false, default: false
    end
  end
end
