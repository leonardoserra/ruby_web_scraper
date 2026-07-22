# frozen_string_literal: true

require 'rtesseract'
require 'fileutils'

module OCRCrawler
  # Wrapper around RTesseract for OCR on images and video frames.
  class OCRExecutor
    NULL_REDIRECT = RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/ ? '> NUL 2>&1' : '> /dev/null 2>&1'

    class << self
      def tesseract_available?
        return @tesseract_available unless @tesseract_available.nil?

        @tesseract_available = system("tesseract --version #{NULL_REDIRECT}") ? true : false
      end

      def ensure_tesseract!
        return if tesseract_available?

        raise <<~ERROR
          Tesseract not installed or not in PATH.
          Please install Tesseract and ensure 'tesseract' is available in your PATH.
        ERROR
      end

      def perform(path)
        ensure_tesseract!
        RTesseract.new(path).to_s.strip
      rescue StandardError => e
        Logger.warn("OCR failed for #{path}: #{e.message}")
        ''
      end

      def batch_from_frames(frames_dir, page_url, video_url, results)
        Dir.glob(File.join(frames_dir, '*.jpg')).each do |frame|
          text = perform(frame)
          results << ResultRecorder.build(page_url, :video_frame, video_url, frame, text)
        end
      end
    end
  end
end
