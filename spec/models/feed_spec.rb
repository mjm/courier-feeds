RSpec.describe Feed do
  describe 'registering a feed' do
    let(:attrs) { { url: 'https://example.com/feed.json' } }
    subject { Feed.register(attrs) }

    context 'when the feed has not been registered before' do
      it 'creates a new feed' do
        expect { subject }.to change { Feed.count }.by 1
      end

      it 'returns the created feed' do
        expect(subject).to be_a Feed
        expect(subject.url).to eq 'https://example.com/feed.json'
      end

      it 'sets timestamps on the created feed' do
        expect(subject.created_at).not_to be_nil
        expect(subject.updated_at).not_to be_nil
        expect(subject.refreshed_at).to be_nil
      end
    end

    context 'when the feed has been registered before' do
      let!(:existing) { Feed.register(attrs) }

      it 'does not create a new feed' do
        expect { subject }.not_to(change { Feed.count })
      end

      it 'returns the existing feed' do
        expect(subject).to eq existing
      end
    end

    context 'when a user id is provided' do
      let(:attrs) { { url: 'https://example.com/feed.json', user_id: 123 } }
      subject { Feed.register(attrs) }

      it 'creates new feed' do
        expect { subject }.to change { Feed.count }.by 1
      end

      it 'registers the feed for the given user' do
        expect(subject.user_ids).to eq [123]
      end
    end
  end

  describe 'adding a user to a feed' do
    let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
    subject { feed.add_user_id(123) }

    context 'when the user does not already have the feed registered' do
      it 'creates a new user feed' do
        expect { subject }.to change { feed.user_feeds_dataset.count }.by 1
      end

      it 'returns the created user feed' do
        expect(subject).to be_a(UserFeed)
        expect(subject.feed_id).to eq feed.id
      end
    end

    context 'when the user has already registered the feed' do
      before { feed.add_user_id(123) }

      it 'raises an error' do
        expect { subject }.to raise_error(Sequel::UniqueConstraintViolation)
      end
    end
  end

  describe 'querying the user ids of a feed' do
    let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
    subject { feed.user_ids }

    context 'when the feed has no users' do
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end

    context 'when the feed has registered users' do
      before do
        feed.add_user_id(456)
        feed.add_user_id(123)
      end

      it 'returns an array with the user ids' do
        expect(subject).to eq [123, 456]
      end
    end
  end

  describe 'querying feeds by user id' do
    subject { Feed.by_user(123) }

    context 'when there are no feeds registered' do
      it { is_expected.to be_empty }
    end

    context 'when there are no feeds registered by that user' do
      let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
      before { feed.add_user_id(456) }

      it { is_expected.to be_empty }
    end

    context 'when there are feeds registered by that user' do
      let(:feed1) { Feed.register(url: 'https://example.com/feed.json') }
      let(:feed2) { Feed.register(url: 'https://example2.com/feed.json') }
      let(:feed3) { Feed.register(url: 'https://example3.com/feed.json') }
      before do
        feed1.add_user_id(123)
        feed1.add_user_id(456)
        feed2.add_user_id(123)
        feed3.add_user_id(456)
      end

      it 'returns the feeds for that user' do
        expect(subject.all).to eq [feed1, feed2]
      end

      it 'can be combined with other dataset filters' do
        dataset = Feed.where(Sequel[:url].like('%2.com%')).by_user(123)
        expect(dataset.all).to eq [feed2]
      end
    end
  end

  describe 'finding by home page URL' do
    let!(:feed) do
      feed = Feed.register(url: 'https://example.com/feed.json')
      feed.update(homepage_url: 'https://example.com/')
      feed.refresh
    end
    let(:found_feeds) { Feed.by_home_page_url(url).to_a }

    context 'when the feed is registered with the exact matching URL' do
      let(:url) { 'https://example.com/' }

      it 'finds the feed' do
        expect(found_feeds).to eq [feed]
      end
    end

    context 'when the feed is registered with a different version of the same URL' do
      let(:url) { 'https://example.com' }

      it 'finds the feed' do
        expect(found_feeds).to eq [feed]
      end
    end

    context 'when the feed is not registered' do
      let(:url) { 'https://example2.com/' }

      it 'does not find the feed' do
        expect(found_feeds).to eq []
      end
    end
  end
end
