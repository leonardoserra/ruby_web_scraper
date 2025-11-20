# frozen_string_literal: true

# Main library entrypoint. Loads all Crawler components and exposes a simple
# OCRCrawler.run method as an execution entrypoint.
require_relative 'ocr_crawler/config'
require_relative 'ocr_crawler/logger'
require_relative 'ocr_crawler/memory_manager'
require_relative 'ocr_crawler/initializer'
require_relative 'ocr_crawler/document_processor'
require_relative 'ocr_crawler/downloader'
require_relative 'ocr_crawler/ffmpeg_helper'
require_relative 'ocr_crawler/ocr_executor'
require_relative 'ocr_crawler/image_manager'
require_relative 'ocr_crawler/video_manager'
require_relative 'ocr_crawler/link_manager'
require_relative 'ocr_crawler/result_recorder'
require_relative 'ocr_crawler/crawler'

# OCRCrawler
# Public API namespace. Call OCRCrawler.run to initialize and execute the
# crawling pipeline with the loaded configuration.
module OCRCrawler
  def self.run
    Initializer.setup
    config = Config.load
    Crawler.new(config).run
  end
end
