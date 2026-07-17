# frozen_string_literal: true

require 'net/http'
require 'uri'
require_relative 'tor_manager'

module OCRCrawler
  # Provides HTTP fetching with optional proxy support. Used by DocumentProcessor
  # and Downloader to route requests through a configurable proxy.
  #
  # If no explicit proxy is configured but Tor + Privoxy are running on localhost,
  # they are auto-detected and used. When tor_circuit_interval is set (>0), the
  # Tor circuit is rotated every N requests, changing the apparent IP address.
  module HTTPClient
    PRIVOXY_URI = 'http://127.0.0.1:8118'

    class << self
      def fetch(uri_or_str, config = {})
        uri = uri_or_str.is_a?(URI) ? uri_or_str : URI.parse(uri_or_str)
        user_agent = (config && config[:user_agent]) || 'ruby-ocr-crawler/1.0'

        maybe_switch_circuit(config)

        request = Net::HTTP::Get.new(uri.request_uri, 'User-Agent' => user_agent)

        http_class_for(config).start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.open_timeout = 5
          http.read_timeout = 10
          http.request(request)
        end
      end

      def http_class_for(config)
        proxy_uri = resolve_proxy_uri(config)
        return Net::HTTP unless proxy_uri

        parsed = URI.parse(proxy_uri)
        Net::HTTP::Proxy(parsed.host, parsed.port, parsed.user, parsed.password)
      end

      private

      def resolve_proxy_uri(config)
        explicit = config && config[:proxy]
        return explicit if explicit && !explicit.empty?

        privoxy_available? ? PRIVOXY_URI : nil
      end

      def privoxy_available?
        return @privoxy_available if defined?(@privoxy_available)

        @privoxy_available = TorManager.available?
      end

      def maybe_switch_circuit(config)
        interval = (config && config[:tor_circuit_interval]).to_i
        return unless interval.positive?
        return unless privoxy_available?

        @request_count = (@request_count || 0) + 1
        return unless (@request_count % interval).zero?

        TorManager.switch_circuit
      end
    end
  end
end
