# frozen_string_literal: true

require 'set'

module OCRCrawler
  class Crawler
    # ::Crawler
    #
    # Purpose
    #    Manage a Crawler instance running all its business logic components.
    # Orchestrates the crawling process: manages the worker queue, threads,
    # shared state (visited/results), and delegates fetching/extraction to other
    # components. Responsible for merging discovered results and triggering GC.
    def initialize(config = Config.load)
      @config = config
      @queue = Queue.new
      @visited = Set.new
      @visited_mutex = Mutex.new
      @results = []
      @results_mutex = Mutex.new

      @recorder = ResultRecorder.new(@config)
      @image_manager = ImageManager.new(@config)
      @video_manager = VideoManager.new(@config)
      @link_manager = LinkManager.new(@config, @queue, @visited, @visited_mutex)
      @memory = MemoryManager.new
    end

    def run
      Array(@config[:start_urls]).each do |u|
        @queue << { url: u.to_s, depth: 0 }
      end

      threads = Array.new(@config[:threads]) do
        Thread.new do
          process_queue
        rescue StandardError => e
          Logger.error("Worker thread error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end

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
      Logger.info("Processing #{url} (depth #{depth})")
      doc = DocumentProcessor.fetch(url)
      return unless doc

      imgs = @image_manager.extract(doc, url)
      vids = @video_manager.extract(doc, url)

      # merge results thread-safely
      @results_mutex.synchronize do
        @results.concat(imgs) if imgs && !imgs.empty?
        @results.concat(vids) if vids && !vids.empty?
      end

      @link_manager.enqueue_links(doc, url, depth)
    ensure
      doc&.remove
    end

    def safe_dequeue
      @queue.pop(true)
    rescue ThreadError
      nil
    end
  end
end
