class IndexController < ApplicationController
  get '/' do
    markdown :index
  end
end
