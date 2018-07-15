require 'bundler/setup'
require 'rack/test'
require 'base64'

ENV['RACK_ENV'] = 'test'
ENV['JWT_SECRET'] = Base64.encode64(Random.new.bytes(32))
ENV['SESSION_SECRET'] = 'super secret'

$LOAD_PATH.unshift File.expand_path(File.join(__dir__, '..'))
require 'config/environment'
require 'app'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module ControllerSpec
  include Rack::Test::Methods

  def app
    App
  end

  def jwt(payload)
    token = JWT.encode(payload, Base64.decode64(ENV['JWT_SECRET']), 'HS256')
    header 'Authorization', "Bearer #{token}"
  end
end
