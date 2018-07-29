require 'base64'

RACK_ENV = (ENV['RACK_ENV'] || 'development').to_sym
Bundler.require(:default, RACK_ENV)

Courier::Service.configure do
  root __dir__, '..'

  database
  background_jobs
end

# Provide the token for this service to use when talking to other
# microservices. This should be used in rare situations where there
# is no current user making the request, such as in background jobs.
Courier::Service::TOKEN = JWT.encode(
  { 'sub' => 'courier-feeds', 'roles' => %w[service] },
  Base64.decode64(ENV['JWT_SECRET']),
  'HS256'
)
