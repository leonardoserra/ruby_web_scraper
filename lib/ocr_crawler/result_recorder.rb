# frozen_string_literal: true

require 'json'
require 'fileutils'

module OCRCrawler
  # ::ResultRecorder
  #
  # Purpose
  #   Handles the result file creation.
  class ResultRecorder
    def initialize(config)
      @config = config
    end

    def self.build(page, type, url, path, text)
      { source_page: page, type: type, url: url, path: path, text: text }
    end

    def save(results)
      FileUtils.mkdir_p(@config[:output_dir])
      file = File.join(@config[:output_dir], 'results.json')
      File.write(file, JSON.pretty_generate(results))
      Logger.info("Results saved to #{file}")
    end
  end
end
