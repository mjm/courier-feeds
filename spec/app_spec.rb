RSpec.describe FeedsHandler, rpc: true do
  subject { App }

  describe '#get_feeds' do
    rpc_method :GetFeeds
    let(:feeds) { response.feeds }

    include_examples 'an unauthenticated request'

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
            refreshed_at: '',
            created_at: String,
            updated_at: String,
            title: '',
            home_page_url: '',
            settings: nil
          },
          {
            id: Integer,
            url: 'https://blog.example.com/feed/json',
            refreshed_at: '',
            created_at: String,
            updated_at: String,
            title: '',
            home_page_url: '',
            settings: nil
          }
        ]
      end
    end
  end

  describe '#get_user_feeds' do
    rpc_method :GetUserFeeds
    let(:request) { { user_id: 123 } }
    let(:feeds) { response.feeds }

    include_examples 'an unauthenticated request'
    include_examples 'a request from another user'

    context 'when the user has no feeds' do
      before { Feed.register(url: 'https://example.com/feed.json') }

      it 'returns an empty list of feeds' do
        expect(feeds).to eq []
      end
    end

    context 'when the user has feeds' do
      let(:feed1) { Feed.register(url: 'https://example.com/feed.json') }
      before do
        feed1.add_user_id(123)
        feed1.update_settings(123, autopost: true)
      end
      let(:feed2) { Feed.register(url: 'https://example2.com/feed.json') }
      before { feed2.add_user_id(456) }

      before do
        feed1.update(title: 'My Cool Blog',
                     homepage_url: 'https://example.com')
      end

      it 'returns a list of feeds registered to the user' do
        expect(feeds.map(&:to_hash)).to match [
          {
            id: Integer,
            url: 'https://example.com/feed.json',
            refreshed_at: '',
            created_at: String,
            updated_at: String,
            title: 'My Cool Blog',
            home_page_url: 'https://example.com',
            settings: { autopost: true }
          }
        ]
      end
    end
  end

  describe '#register_feed' do
    rpc_method :RegisterFeed
    let(:request) { { user_id: 123, url: 'https://example.com/feed.json' } }

    include_examples 'an unauthenticated request'
    include_examples 'a request from another user'

    context 'when the feed is not already registered' do
      before { response }

      it 'returns a Feed message' do
        expect(response).to be_a Courier::Feed
      end

      it 'registers the feed' do
        expect(Feed.first.url).to eq 'https://example.com/feed.json'
      end

      it 'registers the feed for the user' do
        expect(Feed.first.user_ids).to eq [123]
      end

      it 'returns a description of the feed' do
        expect(response.to_hash).to match(
          id: Integer,
          url: 'https://example.com/feed.json',
          refreshed_at: '',
          created_at: String,
          updated_at: String,
          title: '',
          home_page_url: '',
          settings: { autopost: false }
        )
      end
    end

    context 'when the feed has already been registered' do
      let!(:feed) { Feed.register(url: 'https://example.com/feed.json') }
      before do
        feed.update(title: 'My Cool Blog',
                    homepage_url: 'https://example.com')
      end

      context 'and is not registered to this user' do
        before { response }

        it 'returns a Feed message' do
          expect(response).to be_a Courier::Feed
        end

        it 'registers the feed for the user' do
          expect(feed.user_ids).to eq [123]
        end

        it 'includes the title and home page url in the feed response' do
          expect(response.title).to eq 'My Cool Blog'
          expect(response.home_page_url).to eq 'https://example.com'
        end
      end

      context 'and is already registered to this user' do
        before do
          feed.add_user_id(123)
          response
        end

        it 'returns an error response' do
          expect(response).to be_a_twirp_error(
            :already_exists,
            'The user is already registered to this feed.'
          )
        end
      end
    end
  end

  describe '#refresh_feed' do
    rpc_method :RefreshFeed
    let(:feed_id) { 123 }
    let(:request) { { feed_id: feed_id } }

    include_examples 'an unauthenticated request'

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
        expect(response.to_hash).to match(
          status: 'refreshing',
          job_id: String
        )
      end

      it 'enqueues a job to refresh the feed' do
        expect(RefreshFeedWorker).to have_enqueued_sidekiq_job(feed_id)
      end
    end
  end

  describe '#ping' do
    rpc_method :Ping
    let(:request) { { title: 'foo', url: 'https://example.com' } }

    let!(:feed1) do
      Feed.register(url: 'https://example.com/feed.json',
                    homepage_url: 'https://example.com/')
    end
    let!(:feed2) do
      Feed.register(url: 'https://example.com/feed2.json',
                    homepage_url: 'https://example.com/')
    end
    let!(:feed3) do
      Feed.register(url: 'https://example2.com/feed.json',
                    homepage_url: 'https://example2.com/')
    end

    it 'returns a list of the matching feeds' do
      expect(response.feeds.map(&:to_hash)).to match [
        hash_including(url: 'https://example.com/feed.json'),
        hash_including(url: 'https://example.com/feed2.json')
      ]
    end

    it 'enqueues jobs to refresh the matching feeds' do
      response
      expect(RefreshFeedWorker).to have_enqueued_sidekiq_job(feed1.id)
      expect(RefreshFeedWorker).to have_enqueued_sidekiq_job(feed2.id)
      expect(RefreshFeedWorker).not_to have_enqueued_sidekiq_job(feed3.id)
    end

    context 'when no feeds match the URL' do
      let(:request) { { title: 'foo', url: 'https://example3.com/' } }

      it 'returns an empty list' do
        expect(response).to eq Courier::FeedList.new
      end
    end
  end

  describe '#update_feed_settings' do
    rpc_method :UpdateFeedSettings
    let(:request) { { feed_id: feed.id, user_id: 123, settings: settings } }
    let(:settings) { Courier::FeedSettingsChanges.new(autopost: :ON) }
    let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
    before do
      feed.add_user_id(123)
    end

    include_examples 'an unauthenticated request'
    include_examples 'a request from another user'

    it 'changes the affected settings' do
      response
      expect(feed.user_feeds.first.autopost).to be true
    end

    it 'returns a description of the updated feed' do
      expect(response.to_hash).to match(
        id: Integer,
        url: 'https://example.com/feed.json',
        refreshed_at: '',
        created_at: String,
        updated_at: String,
        title: '',
        home_page_url: '',
        settings: { autopost: true }
      )
    end

    context 'when the setting value is unchanged' do
      let(:settings) { Courier::FeedSettingsChanges.new }
      before { feed.update_settings(123, autopost: true) }

      it 'does not change the setting' do
        response
        expect(feed.user_feeds.first.autopost).to be true
      end
    end
  end
end
