require 'rack/parser'
require 'sinatra/json'

class FeedsController < ApplicationController
  use Rack::Parser

  get '/feeds' do
    json Feed.all
  end
end
