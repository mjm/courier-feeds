require 'sinatra/base'
require 'config/environment'

class ApplicationController < Sinatra::Base
  def self.inherited(subclass)
    super
    App.use subclass
  end
end

class App < Sinatra::Base
  disable :show_exceptions
  require_app :controllers
end
