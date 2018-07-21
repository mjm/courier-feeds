require 'pathname'

RACK_ENV = (ENV['RACK_ENV'] || 'development').to_sym
Bundler.require(:default, RACK_ENV)

DB = Sequel.connect(ENV['DATABASE_URL'])
Sequel::Model.plugin :json_serializer

def require_app(dir)
  Pathname
    .new(__dir__)
    .join('..', 'app', dir.to_s)
    .glob('*.rb')
    .each { |file| require file }
end

require_app :models
require_app :middlewares
require_app :helpers
require_app :workers
