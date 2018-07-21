source 'https://rubygems.org'
ruby '2.5.1'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'courier-service', github: 'mjm/courier-service'
gem 'faraday'
gem 'jwt'
gem 'pg'
gem 'puma'
gem 'rack'
gem 'rack-parser'
gem 'rake', '~> 10.0'
gem 'rdiscount'
gem 'sequel'
gem 'sidekiq'
gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-contrib'

group :development do
  gem 'pry'
end

group :test do
  gem 'rack-test'
  gem 'rspec', '~> 3.0'
  gem 'rspec-sidekiq'
  gem 'webmock', require: 'webmock/rspec'
end
