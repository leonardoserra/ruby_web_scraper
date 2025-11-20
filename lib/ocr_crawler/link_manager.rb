# frozen_string_literal: true

require 'uri'
require 'nokogiri'

module OCRCrawler
  class LinkManager
    # ::LinkManager
    # Extracts and normalizes links from a Nokogiri document, enqueues unseen
    # absolute URLs into the shared Queue and tracks visited URLs in a thread-safe way.
    def initialize(config, queue, visited_set, visited_mutex)
      @config = config
      @queue = queue
      @visited = visited_set
      @visited_mutex = visited_mutex
    end

    def enqueue_links(doc, base_url, current_depth)
      return if current_depth.nil?

      max_depth = @config[:max_depth] || 2
      return if current_depth >= max_depth

      selectors = ['a[href]']
      selectors.each do |sel|
        doc.css(sel).each do |node|
          href = node['href']
          next unless href

          begin
            absolute = URI.join(base_url, href).to_s
          rescue URI::Error
            next
          end

          enqueue_if_new(absolute, current_depth + 1)
        end
      end
    end

    private

    def enqueue_if_new(url, depth)
      @visited_mutex.synchronize do
        return if @visited.include?(url)

        @visited.add(url)
        @queue << { url: url, depth: depth }
      end
    end
  end
end
