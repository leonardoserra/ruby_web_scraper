# frozen_string_literal: true

# OCRCrawler
# Top-level namespace for the OCR web crawler components.
module OCRCrawler
  # Logger
  # Minimal logging helper for stdout with three levels: info, warn, error.
  # Keeps logging simple and dependency-free so tests and scripts can run easily.
  class Logger
    def self.info(msg)  = puts("[INFO]  #{msg}")
    def self.warn(msg)  = puts("[WARN]  #{msg}")
    def self.error(msg) = puts("[ERROR] #{msg}")
  end
end
