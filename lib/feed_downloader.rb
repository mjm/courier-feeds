class FeedDownloader
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def posts
    response = Faraday.get(url)
    case response.status
    when 200 then parse_posts(response.body)
    when 404 then raise NotFoundError, url
    end
  end

  private

  def parse_posts(body)
    JSON.parse(body).fetch('items').map { |item| Feed.from_json(item) }
  end

  Feed = Struct.new(:id, :title, :text, :html) do
    def self.from_json(data)
      new(
        data.fetch('id').to_s,
        data.fetch('title', ''),
        data['content_text'],
        data['content_html']
      )
    end
  end

  class NotFoundError < StandardError
    attr_reader :url

    def initialize(url)
      @url = url
      super "Feed could not be found at URL '#{url}'"
    end
  end
end
