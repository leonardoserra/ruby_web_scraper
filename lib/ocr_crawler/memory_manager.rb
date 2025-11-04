# frozen_string_literal: true

require 'fileutils'

module OCRCrawler
  class MemoryManager
    def self.setup_gc
      GC::Profiler.enable
    end

    def self.cleanup
      GC.start(full_mark: true, immediate_sweep: true)
    end

    def self.cleanup_file(path)
      FileUtils.rm_f(path) if File.exist?(path)
    rescue StandardError => e
      Logger.warn('Error cleaning file ' + path.to_s + ': ' + e.message)
    end

    def self.cleanup_directory(path)
      FileUtils.rm_rf(path) if Dir.exist?(path)
    rescue StandardError => e
      Logger.warn('Error cleaning directory ' + path.to_s + ': ' + e.message)
    end

    def maybe_trigger_gc
      @counter ||= 0
      @counter += 1
      return unless (@counter % OCRCrawler::Config.load[:gc_interval]).zero?
      self.class.cleanup
    end
  end
end
