# frozen_string_literal: true

require 'json'
require_relative 'site'

module OCRCrawler
  # Loads and caches config.json with symbolized keys and Site objects.
  module Config
    CONFIG_FILE = 'config.json'

    class << self
      def load(path = File.join(Dir.pwd, CONFIG_FILE))
        return @config if defined?(@config) && @config

        raw = if File.exist?(path)
                content = File.read(path)
                content.strip.empty? ? {} : JSON.parse(content)
              else
                {}
              end
        symbolized = symbolize_keys(raw)
        @config = defaults.merge(symbolized) do |_key, default, value|
          value.is_a?(Hash) ? default.merge(value) : value
        end
        @config[:sites] = build_sites(@config)
        @config[:start_urls] = @config[:sites].map(&:url)
        @config
      end

      def reset_cache!
        @config = nil
      end

      private

      def defaults
        {
          threads: 4,
          output_dir: File.join(Dir.pwd, 'output'),
          frame_rate: 1,
          gc_interval: 100,
          keep_files: false,
          user_agent: 'ruby-ocr-crawler/1.0',
          sites: []
        }
      end

      def build_sites(cfg)
        sites_data = cfg[:sites] || []
        return sites_data.map { |s| Site.new(**s) } unless sites_data.empty?

        if cfg[:start_urls]
          global_media = cfg.dig(:selectors, :images).to_a | cfg.dig(:selectors, :videos).to_a
          global_media = %w[img video] if global_media.empty?
          global_links = cfg.dig(:selectors, :links) || ['a[href]']
          cfg[:start_urls].map do |url|
            Site.new(url: url, media_selectors: global_media, link_selectors: global_links)
          end
        else
          [Site.new(url: 'https://example.com')]
        end
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
