# frozen_string_literal: true

require 'uri'

module OCRCrawler
  class VideoManager
    def initialize(config)
      @config = config
    end

    def extract(doc, page_url, results)
      doc.css('video, source').each do |tag|
        src = tag['src'] || tag['data-src']
        next unless src

        url = URI.join(page_url, src).to_s rescue next
        path = Downloader.download(url, 'videos', @config)
        next unless path

        frames_dir = FFmpegHelper.extract_frames(path, @config)
        OCRExecutor.batch_from_frames(frames_dir, page_url, url, results)
        MemoryManager.cleanup_directory(frames_dir)
        MemoryManager.cleanup_file(path)
      end
    end
  end
end
