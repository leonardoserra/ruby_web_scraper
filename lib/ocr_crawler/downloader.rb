# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

module OCRCrawler
  class Downloader
    BUFFER_SIZE = 16 * 1024 # 16 KB

    def self.download(url, subfolder, config)
      uri = URI.parse(url)
      dir = File.join(config[:output_dir], subfolder)
      FileUtils.mkdir_p(dir)

      filename = "#{Time.now.to_i}_#{File.basename(uri.path)}"
      filename = "#{Time.now.to_i}_resource" if filename.nil? || filename.empty?
      local_path = File.join(dir, filename)

      Logger.info("Downloading #{url} → #{local_path}")

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = config[:user_agent]
        http.request(request) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            Logger.warn('Failed to download ' + url.to_s + ': ' + response.code.to_s + ' ' + response.message)
            return nil
          end

          File.open(local_path, 'wb') do |file|
            response.read_body do |chunk|
              file.write(chunk)
            end
          end
        end
      end

      local_path
    rescue StandardError => e
      Logger.warn('Error downloading ' + url.to_s + ': ' + e.message)
      nil
    end
  end
end
