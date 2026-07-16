# frozen_string_literal: true

require 'uri'

module OCRCrawler
  # Unified media extractor using CSS selectors for both images and videos.
  class MediaManager
    def initialize(config)
      @config = config
    end

    def extract(doc, base_url, selectors)
      nodes = Array(selectors).flat_map { |sel| selector_nodes(doc, sel) }
      results = nodes.map do |node|
        url = extract_url(node)
        next nil if url.nil? || url.strip.empty?

        normalized = normalize_url(base_url, url)
        normalized ? { type: :media, url: normalized, source_page: base_url } : nil
      end.compact
      results.uniq { |r| r[:url] }
    end

    private

    def selector_nodes(doc, sel)
      doc.css(sel).to_a
    rescue Nokogiri::CSS::SyntaxError
      []
    end

    def extract_url(node)
      node['data-original'] || node['src'] || node['data-src'] || node['content'] || node['href'] || node['poster']
    end

    def normalize_url(base, url)
      absolute = URI.join(base, url).to_s
      uri = URI.parse(absolute)
      return nil unless %w[http https].include?(uri.scheme)

      absolute
    rescue URI::Error
      nil
    end
  end
end
