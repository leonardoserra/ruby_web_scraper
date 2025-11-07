# frozen_string_literal: true

module OCRCrawler
  # ::Config
  #
  # Purpose
  #    Class to manage the global project configurations
  # Usage
  #    rake run[START_URL (string),MAX_DEPTH (integer, optional)]
  class Config
    DEFAULTS = {
      start_url: ARGV[0] || abort('Usage: rake run[START_URL,MAX_DEPTH (optional)]'),
      output_dir: 'output',
      max_depth: ARGV[1].to_i, # used to dive into links
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
