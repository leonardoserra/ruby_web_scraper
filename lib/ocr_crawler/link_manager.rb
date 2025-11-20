# frozen_string_literal: true

require 'uri'
require 'nokogiri'

module OCRCrawler
  # ::LinkManager
  # Extracts and normalizes links from a Nokogiri document, enqueues unseen
  # absolute URLs into the shared Queue and tracks visited URLs in a thread-safe way.
  class LinkManager
    def initialize(config, queue, visited_set, visited_mutex)
      @config = config
      @queue = queue
      @visited = visited_set
      @visited_mutex = visited_mutex
    end

    def enqueue_links(doc, base_url, current_depth)
      return if current_depth.nil? || current_depth >= max_depth

      link_nodes(doc).each do |node|
        next unless (href = node['href'])

        if (absolute = resolve_href(base_url, href))
          enqueue_if_new(absolute, current_depth + 1)
        end
      end
    end

    private

    def link_nodes(doc)
      doc.css('a[href]').to_a
    end

    def resolve_href(base, href)
      URI.join(base, href).to_s
    rescue URI::Error
      nil
    end

    def max_depth
      @config[:max_depth] || 2
    end

    def enqueue_if_new(url, depth)
      @visited_mutex.synchronize do
        return if @visited.include?(url)

        @visited.add(url)
        @queue << { url: url, depth: depth }
      end
    end
  end
end
