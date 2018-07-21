require 'feed_downloader'

RSpec.describe FeedDownloader do
  let(:url) { 'https://example.com/feed.json' }
  let(:download_request) { stub_request(:get, url) }

  subject { FeedDownloader.new(url) }

  context 'when the feed is not found' do
    before { download_request.to_return(status: 404) }

    it 'attempts to get the feed' do
      subject.posts rescue nil # rubocop:disable Style/RescueModifier
      expect(download_request).to have_been_requested
    end

    it 'raises an error' do
      expect { subject.posts }.to raise_error(FeedDownloader::NotFoundError)
    end
  end

  context 'when the feed can be loaded successfully' do
    context 'and the feed has no items' do
      before do
        download_request.to_return(status: 200, body: empty_feed_content)
      end

      it 'attempts to get the feed' do
        subject.posts
        expect(download_request).to have_been_requested
      end

      it 'returns an empty array of posts' do
        expect(subject.posts).to be_empty
      end
    end

    context 'and the feed has items' do
      before do
        download_request.to_return(status: 200, body: feed_content)
      end

      it 'attempts to get the feed' do
        subject.posts
        expect(download_request).to have_been_requested
      end

      it 'returns an array of posts' do
        expect(subject.posts).to eq [
          FeedDownloader::Feed.new('123', '', 'This is some content.', nil),
          FeedDownloader::Feed.new(
            '124',
            'My Fancy Post Title',
            nil,
            '<p>I have some thoughts <em>about things</em>!</p>'
          )
        ]
      end
    end
  end

  let(:empty_feed_content) do
    {
      title: 'Example Blog',
      feed_url: 'https://example.com/feed.json',
      items: []
    }.to_json
  end

  let(:feed_content) do
    {
      title: 'Example Blog',
      feed_url: 'https://example.com/feed.json',
      items: [
        {
          id: '123',
          content_text: 'This is some content.'
        },
        {
          id: 124,
          title: 'My Fancy Post Title',
          content_html: '<p>I have some thoughts <em>about things</em>!</p>'
        }
      ]
    }.to_json
  end
end
