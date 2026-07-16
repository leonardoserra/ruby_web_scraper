# frozen_string_literal: true

require 'json'

module OCRCrawler
  module GUI
    # Reads and writes config.json, converts between raw JSON and Site objects.
    module ConfigSerializer
      CONFIG_FILE = File.join(Dir.pwd, 'config.json')

      def self.load
        raw = File.exist?(CONFIG_FILE) ? JSON.parse(File.read(CONFIG_FILE)) : {}
        sites = (raw['sites'] || []).map do |s|
          Site.new(
            url: s['url'] || '',
            max_depth: s['max_depth'] || 1,
            media_selectors: s['media_selectors'] || [],
            link_selectors: s['link_selectors'] || ['a[href]']
          )
        end
        {
          sites: sites,
          threads: raw['threads'] || 4,
          output_dir: raw['output_dir'] || File.join(Dir.pwd, 'output'),
          frame_rate: raw['frame_rate'] || 1,
          gc_interval: raw['gc_interval'] || 100,
          keep_files: raw['keep_files'] == true,
          user_agent: raw['user_agent'] || 'ruby-ocr-crawler/1.0'
        }
      end

      def self.save(data)
        hash = {
          'sites' => data[:sites].map(&:to_h),
          'threads' => data[:threads],
          'output_dir' => data[:output_dir],
          'frame_rate' => data[:frame_rate],
          'gc_interval' => data[:gc_interval],
          'keep_files' => data[:keep_files],
          'user_agent' => data[:user_agent]
        }
        File.write(CONFIG_FILE, JSON.pretty_generate(hash))
      end
    end
  end
end
