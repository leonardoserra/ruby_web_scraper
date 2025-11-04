# frozen_string_literal: true

module OCRCrawler
  class Config
    DEFAULTS = {
      start_url: ARGV[0] || abort('Usage: ruby bin/run.rb START_URL'),
      output_dir: 'output',
      max_depth: 2,
      threads: 4,
      frame_rate: 1,
      gc_interval: 20,
      user_agent: 'RubyOCRCrawler/3.0'
    }.freeze

    def self.load
      DEFAULTS
    end
  end
end
