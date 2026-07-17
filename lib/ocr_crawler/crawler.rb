# frozen_string_literal: true

require 'set'
require_relative 'media_manager'
require_relative 'link_manager'
require_relative 'memory_manager'
require_relative 'document_processor'
require_relative 'result_recorder'

module OCRCrawler
  # Orchestrates the crawl: thread pool, per-site selectors, media/link extraction.
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
      @media_manager = MediaManager.new(@config)
      @link_manager = LinkManager.new(@config, @queue, @visited, @visited_mutex)
      @memory = MemoryManager.new
    end

    def enqueue_start_urls
      sites = @config[:sites] || []
      if sites.empty?
        Array(@config[:start_urls]).each { |u| @queue << { url: u.to_s, depth: 0 } }
        return
      end
      sites.each do |site|
        @queue << {
          url: site.url,
          depth: 0,
          media_selectors: site.media_selectors,
          link_selectors: site.link_selectors,
          max_depth: site.max_depth
        }
      end
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
        process_page(job)
        @memory.maybe_trigger_gc
      end
    end

    def process_page(job)
      Logger.info("Processing #{job[:url]} (depth #{job[:depth]})")
      doc = fetch_document(job[:url])
      return unless doc

      results = extract_media(doc, job[:url], job[:media_selectors])
      merge_results(results)
      enqueue_links_from(doc, job[:url], job[:depth],
                         max_depth: job[:max_depth],
                         media_selectors: job[:media_selectors],
                         link_selectors: job[:link_selectors])
    ensure
      doc&.remove
    end

    def fetch_document(url)
      DocumentProcessor.fetch(url, @config)
    rescue StandardError => e
      Logger.warn("Failed to fetch #{url}: #{e.class}: #{e.message}")
      nil
    end

    def extract_media(doc, url, selectors)
      @media_manager.extract(doc, url, selectors) || []
    end

    def merge_results(results)
      @results_mutex.synchronize do
        @results.concat(results) unless results.empty?
      end
    end

    def enqueue_links_from(doc, url, depth, **extra)
      @link_manager.enqueue_links(doc, url, depth,
                                  site_opts: { link_selectors: extra[:link_selectors],
                                               max_depth: extra[:max_depth] },
                                  extra: extra)
    end

    def safe_dequeue
      @queue.pop(true)
    rescue ThreadError
      nil
    end
  end
end
