RSpec.describe RefreshFeedWorker do
  let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
  let(:downloader) { instance_double('FeedDownloader', posts: []) }
  before { allow(FeedDownloader).to receive(:new).and_return(downloader) }

  it 'updates the refreshed_at time of the feed' do
    subject.perform(feed.id)
    expect(feed.reload.refreshed_at).not_to be_nil
  end

  it 'downloads posts from the feed URL' do
    subject.perform(feed.id)
    expect(FeedDownloader).to have_received(:new).with('https://example.com/feed.json')
  end

  context 'when the feed is registered to multiple users' do
    let(:posts_client) { instance_double(Courier::PostsClient) }
    let(:first_post) do
      Courier::Post.new(id: 'abc', title: 'Foo', content_text: 'bar baz')
    end
    let(:first_post_with_feed) do
      Courier::Post.new(first_post.to_h.merge(feed_id: feed.id))
    end
    let(:second_post) do
      Courier::Post.new(id: 'def', content_html: '<p>Florp!</p>')
    end
    let(:second_post_with_feed) do
      Courier::Post.new(second_post.to_h.merge(feed_id: feed.id))
    end
    before do
      allow(Courier::PostsClient).to receive(:connect) { posts_client }
      allow(downloader).to receive(:posts) { [first_post, second_post] }
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
end
