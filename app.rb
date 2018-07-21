require 'config/environment'

class ApplicationController < Sinatra::Base
  def self.inherited(subclass)
    super
    App.use subclass
    subclass.set :root, App.root
  end
end

class App < Sinatra::Base
  disable :show_exceptions
  set :root, File.join(__dir__, 'app')
  require_app :controllers
end
