# frozen_string_literal: true

require 'socket'

module OCRCrawler
  # Switches Tor circuits so each batch of requests appears to come from a
  # different IP. Connects to Tor's control port (127.0.0.1:9051) and sends
  # SIGNAL NEWNYM. Uses cookie authentication.
  module TorManager
    CONTROL_HOST = '127.0.0.1'
    CONTROL_PORT = 9051

    class << self
      def switch_circuit
        socket = TCPSocket.new(CONTROL_HOST, CONTROL_PORT)
        authenticate(socket)
        send_command(socket, 'SIGNAL NEWNYM')
        socket.close
        true
      rescue StandardError => e
        Logger.warn("Tor circuit switch failed: #{e.message}")
        false
      end

      def available?
        socket = TCPSocket.new(CONTROL_HOST, CONTROL_PORT)
        socket.close
        true
      rescue StandardError
        false
      end

      private

      def authenticate(socket)
        cookie = read_cookie
        hex = cookie.unpack1('H*')
        send_command(socket, "AUTHENTICATE #{hex}")
      end

      def read_cookie
        path = '/var/lib/tor/control_auth_cookie'
        File.binread(path, 32)
      end

      def send_command(socket, command)
        socket.write("#{command}\r\n")
        reply = socket.gets
        raise "Tor control error: #{reply.strip}" unless reply&.start_with?('250')
      end
    end
  end
end
