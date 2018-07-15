require 'sequel'
require 'pathname'
require 'courier/service'

RACK_ENV = (ENV['RACK_ENV'] || 'development').to_sym
Courier::Service.load_environment_variables

DB = Sequel.connect(ENV['DB_URL'])

def require_app(dir)
  Pathname
    .new(__dir__)
    .join('..', 'app', dir.to_s)
    .glob('*.rb')
    .each { |file| require file }
end

require_app :middlewares
require_app :helpers
