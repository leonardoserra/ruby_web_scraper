# frozen_string_literal: true

require 'set'

module OCRCrawler
  # ::Crawler
  #
  # Purpose
  #    Manage a Crawler instance running all its business logic components.
  # Orchestrates the crawling process: manages the worker queue, threads,
  # shared state (visited/results), and delegates fetching/extraction to other
  # components. Responsible for merging discovered results and triggering GC.
  class Crawler
    def initialize(config = Config.load)
      @config = config
      setup_state
      setup_managers
    end

    def run
      enqueue_start_urls
      threads = start_workers
      wait_workers_and_save(threads)
    ensure
      MemoryManager.cleanup
    end

    private

    def setup_state
      @queue = Queue.new
      @visited = Set.new
      @visited_mutex = Mutex.new
      @results = []
      @results_mutex = Mutex.new
    end

    def setup_managers
      @recorder = ResultRecorder.new(@config)
      @image_manager = ImageManager.new(@config)
      @video_manager = VideoManager.new(@config)
      @link_manager = LinkManager.new(@config, @queue, @visited, @visited_mutex)
      @memory = MemoryManager.new
    end

    def enqueue_start_urls
      Array(@config[:start_urls]).each { |u| @queue << { url: u.to_s, depth: 0 } }
    end

    def start_workers
      Array.new(@config[:threads]) do
        Thread.new do
          process_queue
        rescue StandardError => e
          Logger.error("Worker thread error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end
    end

    def wait_workers_and_save(threads)
      threads.each(&:join)
      @recorder.save(@results)
    end

    def process_queue
      while (job = safe_dequeue)
        url, depth = job.values_at(:url, :depth)
        process_page(url, depth)
        @memory.maybe_trigger_gc
      end
    end

    def process_page(url, depth)
      Logger.info("Processing #{url} (depth #{depth})")
      doc = fetch_document(url)
      return unless doc

      imgs, vids = extract_media(doc, url)
      merge_results(imgs, vids)
      enqueue_links_from(doc, url, depth)
    ensure
      doc&.remove
    end

    def fetch_document(url)
      DocumentProcessor.fetch(url)
    rescue StandardError => e
      Logger.warn("Failed to fetch #{url}: #{e.class}: #{e.message}")
      nil
    end

    def extract_media(doc, url)
      imgs = @image_manager.extract(doc, url) || []
      vids = @video_manager.extract(doc, url) || []
      [imgs, vids]
    end

    def merge_results(imgs, vids)
      @results_mutex.synchronize do
        @results.concat(imgs) unless imgs.empty?
        @results.concat(vids) unless vids.empty?
      end
    end

    def enqueue_links_from(doc, url, depth)
      @link_manager.enqueue_links(doc, url, depth)
    end

    def safe_dequeue
      @queue.pop(true)
    rescue ThreadError
      nil
    end
  end
end
