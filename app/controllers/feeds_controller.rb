require 'rack/parser'
require 'sinatra/json'

class FeedsController < ApplicationController
  use Rack::Parser

  get '/feeds' do
    json Feed.all
  end

  get '/users/:user_id/feeds' do
    json Feed.by_user(params[:user_id]).all
  end

  post '/users/:user_id/feeds' do
    feed = Feed.register(params)
    status 201
    json feed
  rescue Sequel::UniqueConstraintViolation
    status 400
    json message: 'The user is already registered to this feed.'
  end
end
