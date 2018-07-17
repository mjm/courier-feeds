RSpec.describe IndexController do
  include ControllerSpec

  describe 'GET /' do
    it 'shows a description of the API' do
      get '/'
      expect(last_response.body).to include '<h1>Courier Feeds</h1>'
      expect(last_response.body).to include '<h3>GET <code>/feeds</code></h3>'
    end
  end
end
