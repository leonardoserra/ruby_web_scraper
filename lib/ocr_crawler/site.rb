# frozen_string_literal: true

module OCRCrawler
  # Value object holding per-site crawl configuration: URL, depth, and CSS selectors.
  class Site
    attr_reader :url, :max_depth, :media_selectors, :link_selectors

    def initialize(url:, max_depth: 1, media_selectors: [], link_selectors: ['a[href]'])
      @url = url
      @max_depth = max_depth
      @media_selectors = media_selectors
      @link_selectors = link_selectors
    end

    def to_h
      { url: @url, max_depth: @max_depth, media_selectors: @media_selectors, link_selectors: @link_selectors }
    end
  end
end
