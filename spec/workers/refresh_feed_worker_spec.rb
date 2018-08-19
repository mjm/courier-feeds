RSpec.describe RefreshFeedWorker do
  let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
  let(:downloader) { instance_double('FeedDownloader', feed: downloaded_feed) }
  let(:downloaded_feed) do
    FeedDownloader::Feed.new(
      'Blog Title',
      'https://example.com',
      '"qwer"',
      'a fake date',
      posts
    )
  end
  let(:posts) { [] }
  before { allow(FeedDownloader).to receive(:new).and_return(downloader) }

  it 'updates the refreshed_at time of the feed' do
    subject.perform(feed.id)
    expect(feed.reload.refreshed_at).not_to be_nil
  end

  it 'downloads posts from the feed URL' do
    subject.perform(feed.id)
    expect(FeedDownloader).to have_received(:new).with(
      'https://example.com/feed.json',
      etag: nil,
      last_modified: nil,
      logger: an_instance_of(Logger)
    )
  end

  it 'updates the caching fields for the feed' do
    subject.perform(feed.id)
    feed.reload
    expect(feed.etag).to eq '"qwer"'
    expect(feed.last_modified_at).to eq 'a fake date'
  end

  context 'when the feed is registered to multiple users' do
    let(:posts_client) { instance_double(Courier::PostsClient) }
    let(:first_post) do
      Courier::Post.new(item_id: 'abc',
                        title: 'Foo',
                        content_text: 'bar baz',
                        published_at: '2018-07-20T19:14:38+00:00',
                        modified_at: '2018-07-20T19:14:38+00:00')
    end
    let(:first_post_with_feed) do
      Courier::Post.new(first_post.to_h.merge(feed_id: feed.id))
    end
    let(:second_post) do
      Courier::Post.new(item_id: 'def', content_html: '<p>Florp!</p>')
    end
    let(:second_post_with_feed) do
      Courier::Post.new(second_post.to_h.merge(feed_id: feed.id))
    end
    let(:posts) { [first_post, second_post] }
    before do
      allow(Courier::PostsClient).to receive(:connect) { posts_client }
    end
    before do
      feed.add_user_id(123)
      feed.add_user_id(234)
    end

    it 'imports each post for each user' do
      [123, 234].each do |user_id|
        expect(posts_client).to receive(:import_post).with(
          user_id: user_id,
          post: first_post_with_feed
        )
        expect(posts_client).to receive(:import_post).with(
          user_id: user_id,
          post: second_post_with_feed
        )
      end

      subject.perform(feed.id)
    end
  end

  context 'when the feed has been fetched before' do
    before do
      feed.update(etag: '"asdf"', last_modified_at: 'fake date')
    end

    it 'passes the caching headers to the feed downloader' do
      expect(FeedDownloader).to receive(:new).with(
        'https://example.com/feed.json',
        etag: '"asdf"',
        last_modified: 'fake date',
        logger: an_instance_of(Logger)
      )
      subject.perform(feed.id)
    end
  end

  context 'when the downloaded feed is not modified' do
    let(:downloaded_feed) { nil } # FeedDownloader returns nil for 304

    before do
      feed.update(etag: '"asdf"', last_modified_at: 'fake date')
    end

    it 'updates the refreshed_at time of the feed' do
      subject.perform(feed.id)
      expect(feed.reload.refreshed_at).not_to be_nil
    end

    it 'does not change the caching fields in the feed' do
      subject.perform(feed.id)
      feed.reload
      expect(feed.etag).to eq '"asdf"'
      expect(feed.last_modified_at).to eq 'fake date'
    end
  end
end
