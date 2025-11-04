# frozen_string_literal: true

module OCRCrawler
  class Crawler
    def initialize(config)
      @config = config
      @queue = Queue.new
      @visited = {}
      @results = []
      @recorder = ResultRecorder.new(config)
      @image_manager = ImageManager.new(config)
      @video_manager = VideoManager.new(config)
      @link_manager = LinkManager.new(config, @queue, @visited)
      @memory = MemoryManager.new
    end

    def run
      @queue << { url: @config[:start_url], depth: 0 }
      threads = Array.new(@config[:threads]) { Thread.new { process_queue } }
      threads.each(&:join)
      @recorder.save(@results)
    ensure
      MemoryManager.cleanup
    end

    private

    def process_queue
      while (job = safe_dequeue)
        url, depth = job.values_at(:url, :depth)
        process_page(url, depth)
        @memory.maybe_trigger_gc
      end
    end

    def process_page(url, depth)
      Logger.info('Processing ' + url.to_s + ' (depth ' + depth.to_s + ')')
      doc = DocumentProcessor.fetch(url)
      return unless doc
      @image_manager.extract(doc, url, @results)
      @video_manager.extract(doc, url, @results)
      @link_manager.enqueue_links(doc, url, depth)
    ensure
      doc&.remove
    end

    def safe_dequeue
      @queue.pop(true) rescue nil
    end
  end
end
