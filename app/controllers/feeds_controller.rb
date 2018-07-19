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
end
