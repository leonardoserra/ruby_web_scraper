# frozen_string_literal: true

# Import all the modules needed.
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

# Entry point to start the execution.
module OCRCrawler
  def self.run
    Initializer.setup
    config = Config.load
    Crawler.new(config).run
  end
end
