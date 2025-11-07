# frozen_string_literal: true

require 'open-uri'
require 'uri'
require 'nokogiri'

module OCRCrawler
  # ::DocumentProcessor
  #
  # Purpose
  #    Parse the HTML document downloaded from the url.
  class DocumentProcessor
    def self.fetch(url)
      html = URI.parse(url).read
      # TODO: should remove the html tag im not interested.
      Nokogiri::HTML(html)
    rescue StandardError => e
      Logger.warn("Failed to fetch #{url}: #{e.message}")
      nil
    end
  end
end
