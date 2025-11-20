# frozen_string_literal: true

require 'fileutils'

module OCRCrawler
  # ::MemoryManager
  # Provides helpers to trigger/force Ruby GC and to remove temporary files or
  # directories. Exposes class-level cleanup utilities and an instance method to
  # trigger GC periodically based on an internal counter.
  class MemoryManager
    class << self
      def setup_gc
        GC::Profiler.enable
      end

      def cleanup
        GC.start(full_mark: true, immediate_sweep: true)
      end

      def cleanup_file(path)
        FileUtils.rm_f(path)
      rescue StandardError => e
        Logger.warn("Error cleaning file #{path}: #{e.message}")
      end

      def cleanup_directory(path)
        FileUtils.rm_rf(path)
      rescue StandardError => e
        Logger.warn("Error cleaning directory #{path}: #{e.message}")
      end
    end

    def maybe_trigger_gc
      @counter ||= 0
      @counter += 1
      return unless (@counter % OCRCrawler::Config.load[:gc_interval]).zero?

      self.class.cleanup
    end
  end
end
