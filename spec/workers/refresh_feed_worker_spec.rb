RSpec.describe RefreshFeedWorker do
  let(:feed) { Feed.register(url: 'https://example.com/feed.json') }
  before { subject.perform(feed.id) }

  it 'updates the refreshed_at time of the feed' do
    expect(feed.reload.refreshed_at).not_to be_nil
  end
end
