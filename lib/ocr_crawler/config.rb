# frozen_string_literal: true

require 'yaml'

module OCRCrawler
  # OCRCrawler::Config
  # Responsible for loading and providing configuration values for the crawler.
  # Loads defaults and merges them with a YAML configuration file. Exposes a
  # simple programmatic API (Config.load) returning a Hash of symbolized keys.
  module Config
    class << self
      def load(path = File.join(Dir.pwd, 'config.yaml'))
        return @config if defined?(@config) && @config

        raw = File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
        @config = defaults.merge(symbolize_keys(raw))
      end

      private

      def defaults
        base_defaults.merge(feature_flags).merge(selector_defaults)
      end

      def base_defaults
        {
          start_urls: ['https://example.com'],
          threads: 4,
          output_dir: File.join(Dir.pwd, 'output'),
          frame_rate: 1,
          gc_interval: 100
        }
      end

      def selector_defaults
        { selectors: { images: ['img'], videos: ['video'] } }
      end

      def feature_flags
        { keep_files: false }
      end

      def symbolize_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = symbolize_keys(v) }
        when Array
          obj.map { |i| symbolize_keys(i) }
        else
          obj
        end
      end
    end
  end
end
