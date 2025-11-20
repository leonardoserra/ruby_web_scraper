# frozen_string_literal: true

require 'fileutils'

# OCRCrawler
# Top-level namespace for the OCR web crawler components.
module OCRCrawler
  # Initializer
  # Prepares the runtime environment (creates output directories, enables GC
  # profiler if configured, and logs an initialization message).
  class Initializer
    class << self
      def setup
        create_directories
        MemoryManager.setup_gc if OCRCrawler::Config.load[:gc_interval].to_i.positive?
        Logger.info(init_message)
      end

      def init_message
        <<~MSG
          OCRCrawler environment initialized.
          Configurations: #{OCRCrawler::Config.load}
          Output directory: #{OCRCrawler::Config.load[:output_dir]}
          Created directories: images, videos, video_frames
        MSG
      end

      def create_directories
        directories.each do |dir|
          FileUtils.mkdir_p(File.join(OCRCrawler::Config.load[:output_dir], dir))
        end
      end

      def directories
        %w[images videos video_frames]
      end
    end
  end
end
