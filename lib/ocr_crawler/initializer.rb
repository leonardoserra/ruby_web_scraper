# frozen_string_literal: true

require 'fileutils'

module OCRCrawler
  # ::Initializer
  #
  # Purpose
  #   Bootstraps the OCRCrawler runtime by preparing the filesystem and runtime
  #   environment so the remainder of the application can run reliably.
  class Initializer
    class << self
      def setup
        create_directories
        MemoryManager.setup_gc
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
