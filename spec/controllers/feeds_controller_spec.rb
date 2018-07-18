RSpec.describe FeedsController do
  include ControllerSpec

  describe 'GET /feeds' do
    let(:parsed_feeds) { JSON.parse(last_response.body) }
    context 'when there are no feeds' do
      it 'returns an empty JSON array' do
        get '/feeds'
        expect(parsed_feeds).to eq []
      end
    end

    context 'when there are some feeds' do
      before do
        Feed.register(url: 'https://example.com/feed.json')
        Feed.register(url: 'https://blog.example.com/feed/json')
      end

      it 'returns a JSON array of the feeds' do
        get '/feeds'
        expect(parsed_feeds).to match [
          {
            'id' => Integer,
            'url' => 'https://example.com/feed.json',
            'refreshed_at' => nil,
            'created_at' => String,
            'updated_at' => String
          },
          {
            'id' => Integer,
            'url' => 'https://blog.example.com/feed/json',
            'refreshed_at' => nil,
            'created_at' => String,
            'updated_at' => String
          }
        ]
      end
    end
  end
end
