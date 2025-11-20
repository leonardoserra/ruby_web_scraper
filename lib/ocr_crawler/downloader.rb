# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

# OCRCrawler
# Top-level namespace for the OCR web crawler components.
module OCRCrawler
  # Downloader
  # Handles HTTP downloads of remote resources (images, videos, etc.).
  # Exposes a simple class method `download` that saves a remote resource to
  # a configured output subfolder and returns the local path or nil on error.
  class Downloader
    BUFFER_SIZE = 16 * 1024

    def self.download(url, subfolder, config)
      uri = URI.parse(url)
      local_path = prepare_path(uri, subfolder, config)
      Logger.info("Downloading #{url} → #{local_path}")
      request = build_request(uri, config)
      perform_request(uri, local_path, request)
    rescue StandardError => e
      Logger.warn("Error downloading #{url}: #{e.message}")
      nil
    end

    private_class_method def self.prepare_path(uri, subfolder, config)
      dir = File.join(config[:output_dir], subfolder)
      FileUtils.mkdir_p(dir)
      filename = safe_filename(uri)
      File.join(dir, filename)
    end

    private_class_method def self.safe_filename(uri)
      base = File.basename(uri.path)
      base = 'resource' if base.nil? || base.empty?
      "#{Time.now.to_i}_#{base}".gsub(/[^\w.-]/, '_')
    end

    private_class_method def self.build_request(uri, config)
      Net::HTTP::Get.new(uri.request_uri).tap do |req|
        req['User-Agent'] = (config && config[:user_agent]) || 'ruby-ocr-crawler/1.0'
      end
    end

    private_class_method def self.perform_request(uri, local_path, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request) do |response|
          return warn_and_nil(uri, response) unless response.is_a?(Net::HTTPSuccess)

          write_response_body(response, local_path)
        end
      end
      local_path
    end

    private_class_method def self.warn_and_nil(uri, response)
      Logger.warn("Failed to download #{uri}: #{response.code} #{response.message}")
      nil
    end

    private_class_method def self.write_response_body(response, local_path)
      File.open(local_path, 'wb') do |file|
        response.read_body { |chunk| file.write(chunk) }
      end
    end
  end
end
