# frozen_string_literal: true

require 'uri'
require 'nokogiri'
require_relative 'http_client'

# OCRCrawler
# Top-level namespace for the OCR web crawler components.
module OCRCrawler
  # DocumentProcessor
  # Fetches an HTML document from a URL and parses it into a Nokogiri document.
  # Returns a Nokogiri::HTML::Document or nil on failure.
  class DocumentProcessor
    def self.fetch(url, config = {})
      response = HTTPClient.fetch(url, config)
      return nil unless response.is_a?(Net::HTTPSuccess)

      Nokogiri::HTML(response.body)
    rescue StandardError => e
      Logger.warn("Failed to fetch #{url}: #{e.message}")
      nil
    end
  end
end
