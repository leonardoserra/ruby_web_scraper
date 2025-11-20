# frozen_string_literal: true

require 'uri'

module OCRCrawler
  class ImageManager
    # OCRCrawler::ImageManager
    # Responsible for discovering image resources in a Nokogiri document using
    # configured CSS selectors. Returns an array of result hashes with absolute URLs.
    def initialize(config)
      @config = config
      @selectors = Array(@config.dig(:selectors, :images) || ['img'])
    end

    # returns array of result hashes (not directly mutating shared array)
    def extract(doc, base_url)
      nodes = @selectors.flat_map { |sel| selector_nodes(doc, sel) }
      results = nodes.map do |node|
        url = extract_url(node)
        next nil if url.nil? || url.strip.empty?

        normalized = normalize_url(base_url, url)
        normalized ? build_result(normalized, base_url) : nil
      end.compact
      results.uniq { |r| r[:source] }
    end

    private

    def selector_nodes(doc, sel)
      doc.css(sel).to_a
    end

    def extract_url(node)
      node['src'] || node['data-src'] || node['content'] || node['href']
    end

    def normalize_url(base, url)
      URI.join(base, url).to_s
    rescue URI::Error
      nil
    end

    def build_result(absolute, base_url)
      { type: 'image', source: absolute, page: base_url }
    end
  end
end
