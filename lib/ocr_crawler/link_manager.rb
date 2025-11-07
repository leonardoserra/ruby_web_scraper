# frozen_string_literal: true

require 'uri'

module OCRCrawler
  # ::LinkManager
  #
  # Purpose
  #    Manages the link on the website and visit the
  #    sub link based on the max_depth
  class LinkManager
    def initialize(config, queue, visited)
      @config = config
      @queue = queue
      @visited = visited
      @mutex = Mutex.new
    end

    def enqueue_links(doc, base_url, depth)
      return if depth >= @config[:max_depth]

      doc.css('a[href]').each do |link|
        href = link['href']
        next unless href

        url = normalize_url(href, base_url)
        next unless url
        next if visited?(url)

        enqueue(url, depth + 1)
      end
    end

    private

    def visited?(url)
      @mutex.synchronize { @visited.key?(url) }
    end

    def enqueue(url, depth)
      @mutex.synchronize do
        @visited[url] = true
        @queue << { url: url, depth: depth }
      end
    end

    def normalize_url(href, base)
      URI.join(base, href).to_s
    rescue StandardError
      nil
    end
  end
end
