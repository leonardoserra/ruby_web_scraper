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
    def self.fetch(url)
      html = URI.parse(url).read
      Nokogiri::HTML(html)
    rescue StandardError => e
      Logger.warn("Failed to fetch #{url}: #{e.message}")
      nil
    end
  end
end
