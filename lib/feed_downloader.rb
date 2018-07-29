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
    JSON.parse(body).fetch('items').map do |item|
      Courier::Post.new(
        id: item.fetch('id').to_s,
        title: item.fetch('title', ''),
        content_text: item.fetch('content_text', ''),
        content_html: item.fetch('content_html', '')
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
