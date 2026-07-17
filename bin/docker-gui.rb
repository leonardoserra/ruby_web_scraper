#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rbconfig'

OS = case RbConfig::CONFIG['host_os']
     when /linux/   then :linux
     when /darwin/  then :macos
     when /mswin|mingw|cygwin/ then :windows
     else :unknown
     end

def info(msg) = puts "[INFO] #{msg}"
def err(msg)  = puts "[ERROR] #{msg}"
def run(cmd)  = system(cmd) || raise("Command failed: #{cmd}")

case OS
when :linux
  info 'Detected Linux — using X11 socket forwarding'
  run 'xhost +local:'
  exec 'docker compose run --rm ' \
       "-e DISPLAY=#{ENV.fetch('DISPLAY', nil)} " \
       '-v /tmp/.X11-unix:/tmp/.X11-unix ' \
       'ocr_crawler ruby bin/gui.rb'

when :macos
  info 'Detected macOS'
  xquartz = '/Applications/Utilities/XQuartz.app'
  unless Dir.exist?(xquartz)
    err 'XQuartz not found. Install it with:'
    err '  brew install --cask xquartz'
    err 'Then log out and back in, then re-run this script.'
    exit 1
  end

  begin
    run 'xhost +127.0.0.1'
  rescue StandardError
    warn 'xhost not available, continuing...'
  end

  socat_pid = fork do
    exec 'socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:/tmp/.X11-unix/X0'
  end
  at_exit do
    Process.kill('TERM', socat_pid)
  rescue StandardError
    nil
  end

  info 'Starting GUI in Docker...'
  exec 'docker compose run --rm ' \
       '-e DISPLAY=host.docker.internal:0 ' \
       'ocr_crawler ruby bin/gui.rb'

when :windows
  puts
  puts 'Windows detected. Two options:'
  puts
  puts 'Option 1 — WSLg (Windows 11):'
  puts '  Run this script from within WSL (Ubuntu), and it will'
  puts '  work automatically with X11 forwarding via WSLg.'
  puts
  puts 'Option 2 — VcXsrv:'
  puts '  1. Install VcXsrv (https://sourceforge.net/projects/vcxsrv/)'
  puts "  2. Launch XLaunch with 'Disable access control' enabled"
  puts '  3. Run:'
  puts '     docker compose run --rm -e DISPLAY=host.docker.internal:0 ocr_crawler ruby bin/gui.rb'
  puts

else
  err "Unsupported OS: #{RbConfig::CONFIG['host_os']}"
  err 'Run the GUI natively instead: ruby bin/gui.rb'
  exit 1
end
