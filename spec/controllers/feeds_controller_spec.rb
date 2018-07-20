RSpec.describe FeedsController do
  include ControllerSpec

  describe 'GET /feeds' do
    let(:parsed_feeds) { JSON.parse(last_response.body) }

    it 'is documented on the index page' do
      get '/'
      expect(last_response.body).to include 'GET <code>/feeds</code>'
    end

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

    it 'is documented on the index page' do
      get '/'
      expect(last_response.body).to include 'GET <code>/users/:user_id/feeds'
    end

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

  describe 'POST /users/:user_id/feeds' do
    let(:body) { { url: 'https://example.com/feed.json' } }
    let(:parsed_feed) { JSON.parse(last_response.body) }

    it 'is documented on the index page' do
      get '/'
      expect(last_response.body).to include 'POST <code>/users/:user_id/feeds'
    end

    context 'when the feed is not already registered' do
      before do
        header 'Content-Type', 'application/json'
        post '/users/123/feeds', body.to_json
      end

      it 'returns a 201 response' do
        expect(last_response.status).to be 201
      end

      it 'registers the feed' do
        expect(Feed.first.url).to eq 'https://example.com/feed.json'
      end

      it 'registers the feed for the user' do
        expect(Feed.first.user_ids).to eq [123]
      end

      it 'returns a JSON description of the feed' do
        expect(parsed_feed).to match(
          'id' => Integer,
          'url' => 'https://example.com/feed.json',
          'refreshed_at' => nil,
          'created_at' => String,
          'updated_at' => String
        )
      end
    end

    context 'when the feed has already been registered' do
      let!(:feed) { Feed.register(body) }

      context 'and is not registered to this user' do
        before do
          header 'Content-Type', 'application/json'
          post '/users/123/feeds', body.to_json
        end

        it 'returns a 201 response' do
          expect(last_response.status).to be 201
        end

        it 'registers the feed for the user' do
          expect(feed.user_ids).to eq [123]
        end
      end

      context 'and it is already registered to this user' do
        before do
          feed.add_user_id(123)
          header 'Content-Type', 'application/json'
          post '/users/123/feeds', body.to_json
        end

        it 'returns a 400 response' do
          expect(last_response.status).to be 400
        end

        it 'returns an error payload' do
          expect(parsed_feed).to match(
            'message' => 'The user is already registered to this feed.'
          )
        end
      end
    end
  end
end
