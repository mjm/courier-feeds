class IndexController < ApplicationController
  get '/' do
    markdown :index, layout_engine: :erb
  end
end
