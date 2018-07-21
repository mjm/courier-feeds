RSpec.describe RefreshFeedWorker do
  let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
  let(:downloader) { instance_double('FeedDownloader', posts: []) }
  before { allow(FeedDownloader).to receive(:new).and_return(downloader) }
  before { subject.perform(feed.id) }

  it 'updates the refreshed_at time of the feed' do
    expect(feed.reload.refreshed_at).not_to be_nil
  end

  it 'downloads posts from the feed URL' do
    expect(FeedDownloader).to have_received(:new).with('https://example.com/feed.json')
  end
end
