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

  describe 'GET /users/:user_id/feeds' do
    let(:parsed_feeds) { JSON.parse(last_response.body) }

    context 'when the user has no feeds' do
      before { Feed.register(url: 'https://example.com/feed.json') }

      it 'returns an empty JSON array' do
        get '/users/123/feeds'
        expect(parsed_feeds).to eq []
      end
    end

    context 'when the user has feeds' do
      let(:feed1) { Feed.register(url: 'https://example.com/feed.json') }
      before { feed1.add_user_id(123) }
      let(:feed2) { Feed.register(url: 'https://example2.com/feed.json') }
      before { feed2.add_user_id(456) }

      it 'returns a JSON array of feeds registered to the user' do
        get '/users/123/feeds'
        expect(parsed_feeds).to match [
          {
            'id' => Integer,
            'url' => 'https://example.com/feed.json',
            'refreshed_at' => nil,
            'created_at' => String,
            'updated_at' => String
          }
        ]
      end
    end

    context 'when the user id is not a number' do
      it 'raises an error' do
        expect do
          get '/users/foo-bar/feeds'
        end.to raise_error(Sequel::DatabaseError)
      end
    end
  end
end
