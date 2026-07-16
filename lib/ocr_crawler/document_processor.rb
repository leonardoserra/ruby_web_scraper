# frozen_string_literal: true

require 'open-uri'
require 'uri'
require 'nokogiri'

# OCRCrawler
# Top-level namespace for the OCR web crawler components.
module OCRCrawler
  # DocumentProcessor
  # Fetches an HTML document from a URL and parses it into a Nokogiri document.
  # Returns a Nokogiri::HTML::Document or nil on failure.
  class DocumentProcessor
    def self.fetch(url, config = {})
      user_agent = (config && config[:user_agent]) || 'ruby-ocr-crawler/1.0'
      html = URI.parse(url).read('User-Agent' => user_agent)
      Nokogiri::HTML(html)
    rescue StandardError => e
      Logger.warn("Failed to fetch #{url}: #{e.message}")
      nil
    end
  end
end
