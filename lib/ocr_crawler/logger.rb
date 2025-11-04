# frozen_string_literal: true

module OCRCrawler
  class Logger
    def self.info(msg) = puts("[INFO]  #{msg}")
    def self.warn(msg) = puts("[WARN]  #{msg}")
    def self.error(msg) = puts("[ERROR] #{msg}")
  end
end
