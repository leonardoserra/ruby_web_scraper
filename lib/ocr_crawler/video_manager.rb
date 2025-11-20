# frozen_string_literal: true

require 'uri'

module OCRCrawler
  # OCRCrawler::VideoManager
  # Finds video-related resources using configured selectors and returns result
  # hashes. Downloading and frame extraction are handled elsewhere (e.g. Downloader / FFmpegHelper).
  class VideoManager
    def initialize(config)
      @config = config
      @selectors = Array(@config.dig(:selectors, :videos) || ['video'])
      @frame_rate = @config[:frame_rate] || 1
      @output_dir = @config[:output_dir]
    end

    # returns array of result hashes
    def extract(doc, base_url)
      nodes = @selectors.flat_map { |sel| selector_nodes(doc, sel) }
      results = nodes.map { |node| process_node(node, base_url) }.compact
      results.uniq { |r| r[:source] }
    end

    private

    def selector_nodes(doc, sel)
      doc.css(sel).to_a
    rescue Nokogiri::CSS::SyntaxError
      []
    end

    def process_node(node, base_url)
      url = extract_url(node)
      return nil if url.nil? || url.strip.empty?

      normalized = normalize_url(base_url, url)
      normalized ? build_result(normalized, base_url) : nil
    end

    def extract_url(node)
      node['src'] || node['data-src'] || node['content'] || node['href'] || node['poster']
    end

    def normalize_url(base, url)
      absolute = URI.join(base, url).to_s
      uri = URI.parse(absolute)
      return nil unless %w[http https].include?(uri.scheme)

      absolute
    rescue URI::Error
      nil
    end

    def build_result(absolute, base_url)
      { type: :video, source: absolute, page: base_url }
    end
  end
end
