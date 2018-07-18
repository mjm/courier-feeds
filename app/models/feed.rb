class Feed < Sequel::Model(DB[:feeds])
  plugin :timestamps, update_on_create: true

  def self.register(attrs)
    find_or_create(attrs)
  end
end
