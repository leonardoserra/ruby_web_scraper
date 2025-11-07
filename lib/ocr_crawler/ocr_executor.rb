# frozen_string_literal: true

require 'rtesseract'
require 'fileutils'

module OCRCrawler
  # ::OCRExecutor
  #
  # Purpose
  #    Tesseract ruby handler to run the OCR (Optical Character Recognition)
  class OCRExecutor
    class << self
      def tesseract_available?
        system('tesseract --version > NUL 2>&1') || system('tesseract --version > /dev/null 2>&1')
      end

      def ensure_tesseract!
        return if tesseract_available?

        raise "Tesseract not installed or not in PATH. Please install Tesseract and ensure 'tesseract' is available in your PATH."
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
