# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

module OCRCrawler
  class DocumentProcessor
    def self.fetch(url)
      html = URI.open(url, 'User-Agent' => OCRCrawler::Config.load[:user_agent], &:read)
      Nokogiri::HTML(html)
    rescue StandardError => e
      Logger.warn('Failed to fetch ' + url.to_s + ': ' + e.message)
      nil
    end
  end
end
