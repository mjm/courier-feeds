RSpec.describe FeedsHandler do
  subject { App }

  Token = Courier::Middleware::JWTToken
  let(:token) { Token.new('sub' => 'example', 'uid' => 123) }
  let(:other_token) { Token.new('sub' => 'example2', 'uid' => 124) }
  let(:env) { {} }

  describe '#get_feeds' do
    let(:response) { subject.call_rpc(:GetFeeds, {}, env) }
    let(:feeds) { response.feeds }

    context 'when no auth token in provided' do
      it 'returns an unauthenticated error' do
        expect(response).to be_a_twirp_error :unauthenticated
      end
    end

    context 'when an auth token is provided' do
      let(:env) { { token: token } }

      context 'when there are no feeds' do
        it 'returns an empty list of feeds' do
          expect(feeds).to eq []
        end
      end

      context 'when there are some feeds' do
        before do
          Feed.register(url: 'https://example.com/feed.json')
          Feed.register(url: 'https://blog.example.com/feed/json')
        end

        it 'returns a list of all the feeds' do
          expect(feeds.map(&:to_hash)).to match [
            {
              id: Integer,
              url: 'https://example.com/feed.json',
              refreshed_at: nil,
              created_at: { seconds: Integer, nanos: Integer },
              updated_at: { seconds: Integer, nanos: Integer }
            },
            {
              id: Integer,
              url: 'https://blog.example.com/feed/json',
              refreshed_at: nil,
              created_at: { seconds: Integer, nanos: Integer },
              updated_at: { seconds: Integer, nanos: Integer }
            }
          ]
        end
      end
    end
  end

  describe '#get_user_feeds' do
    let(:response) { subject.call_rpc(:GetUserFeeds, { user_id: 123 }, env) }
    let(:feeds) { response.feeds }

    context 'when no auth token is provided' do
      it 'returns an unauthenticated error' do
        expect(response).to be_a_twirp_error :unauthenticated
      end
    end

    context 'when the user does not match the auth token' do
      let(:env) { { token: other_token } }

      it 'returns a forbidden error' do
        expect(response).to be_a_twirp_error :permission_denied
      end
    end

    context 'when the user matches the auth token' do
      let(:env) { { token: token } }

      context 'when the user has no feeds' do
        before { Feed.register(url: 'https://example.com/feed.json') }

        it 'returns an empty list of feeds' do
          expect(feeds).to eq []
        end
      end

      context 'when the user has feeds' do
        let(:feed1) { Feed.register(url: 'https://example.com/feed.json') }
        before { feed1.add_user_id(123) }
        let(:feed2) { Feed.register(url: 'https://example2.com/feed.json') }
        before { feed2.add_user_id(456) }

        it 'returns a list of feeds registered to the user' do
          expect(feeds.map(&:to_hash)).to match [
            {
              id: Integer,
              url: 'https://example.com/feed.json',
              refreshed_at: nil,
              created_at: { seconds: Integer, nanos: Integer },
              updated_at: { seconds: Integer, nanos: Integer }
            }
          ]
        end
      end
    end
  end

  describe '#register_feed' do
    let(:request) { { user_id: 123, url: 'https://example.com/feed.json' } }
    let(:created_feed) { subject.call_rpc :RegisterFeed, request, env }

    context 'when no auth token is provided' do
      it 'returns an unauthenticated error' do
        expect(created_feed).to be_a_twirp_error :unauthenticated
      end
    end

    context 'when the user id does not match the auth token' do
      let(:env) { { token: other_token } }

      it 'returns a forbidden error' do
        expect(created_feed).to be_a_twirp_error :permission_denied
      end
    end

    context 'when the user id matches the auth token' do
      let(:env) { { token: token } }

      context 'when the feed is not already registered' do
        before { created_feed }

        it 'returns a Feed message' do
          expect(created_feed).to be_a Courier::Feed
        end

        it 'registers the feed' do
          expect(Feed.first.url).to eq 'https://example.com/feed.json'
        end

        it 'registers the feed for the user' do
          expect(Feed.first.user_ids).to eq [123]
        end

        it 'returns a description of the feed' do
          expect(created_feed.to_hash).to match({
            id: Integer,
            url: 'https://example.com/feed.json',
            refreshed_at: nil,
            created_at: { seconds: Integer, nanos: Integer },
            updated_at: { seconds: Integer, nanos: Integer }
          })
        end
      end

      context 'when the feed has already been registered' do
        let!(:feed) { Feed.register(url: 'https://example.com/feed.json') }

        context 'and is not registered to this user' do
          before { created_feed }

          it 'returns a Feed message' do
            expect(created_feed).to be_a Courier::Feed
          end

          it 'registers the feed for the user' do
            expect(feed.user_ids).to eq [123]
          end
        end

        context 'and is already registered to this user' do
          before do
            feed.add_user_id(123)
            created_feed
          end

          it 'returns an error response' do
            expect(created_feed).to be_a_twirp_error(
              :already_exists,
              'The user is already registered to this feed.'
            )
          end
        end
      end
    end
  end

  describe '#refresh_feed' do
    let(:feed_id) { 123 }
    let(:response) { subject.call_rpc(:RefreshFeed, { feed_id: feed_id }, env) }

    context 'when no auth token is provided' do
      it 'returns an unauthenticated error' do
        expect(response).to be_a_twirp_error :unauthenticated
      end
    end

    context 'when an auth token is provided' do
      let(:env) { { token: token } }

      context 'when the feed does not exist' do
        before { response }

        it 'returns an error response' do
          expect(response).to be_a_twirp_error(
            :not_found,
            'There is no feed with the given ID.'
          )
        end

        it 'does not enqueue a job to refresh the feed' do
          expect(RefreshFeedWorker).not_to have_enqueued_sidekiq_job
        end
      end

      context 'when the feed exists' do
        let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
        let(:feed_id) { feed.id }

        before { response }

        it 'returns a job status message' do
          expect(response.to_hash).to match({
            status: 'refreshing',
            job_id: String
          })
        end

        it 'enqueues a job to refresh the feed' do
          expect(RefreshFeedWorker).to have_enqueued_sidekiq_job(feed_id)
        end
      end
    end
  end
end
