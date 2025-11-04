# frozen_string_literal: true

require 'uri'

module OCRCrawler
  class ImageManager
    def initialize(config)
      @config = config
    end

    def extract(doc, page_url, results)
      doc.css('img').each do |img|
        src = img['src'] || img['data-src']
        next unless src

        url = URI.join(page_url, src).to_s rescue next
        path = Downloader.download(url, 'images', @config)
        next unless path

        text = OCRExecutor.perform(path)
        results << ResultRecorder.build(page_url, :image, url, path, text)
        MemoryManager.cleanup_file(path)
      end
    end
  end
end
