source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'courier-service', github: 'mjm/courier-service'
gem 'jwt'
gem 'pg'
gem 'puma'
gem 'rack'
gem 'rake', '~> 10.0'
gem 'sequel'
gem 'sinatra'

group :development do
  gem 'pry'
end

group :test do
  gem 'rack-test'
  gem 'rspec', '~> 3.0'
end

group :production do
  gem 'google-cloud-storage'
end
