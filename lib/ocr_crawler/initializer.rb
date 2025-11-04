# frozen_string_literal: true

require 'fileutils'

module OCRCrawler
  class Initializer
    def self.setup
      create_directories
      MemoryManager.setup_gc
      Logger.info('Environment initialized.')
    end

    def self.create_directories
      %w[images videos video_frames].each do |dir|
        FileUtils.mkdir_p(File.join(OCRCrawler::Config.load[:output_dir], dir))
      end
    end
  end
end
