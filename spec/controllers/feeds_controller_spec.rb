RSpec.describe FeedsController do
  include ControllerSpec

  describe 'GET /feeds' do
    context 'when there are no feeds' do
      it 'returns an empty JSON array' do
        get '/feeds'
        expect(JSON.parse(last_response.body)).to eq []
      end
    end
  end
end
