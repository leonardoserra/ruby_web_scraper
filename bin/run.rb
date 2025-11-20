#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'json'
require 'pathname'

require_relative '../lib/ocr_crawler/config'
require_relative '../lib/ocr_crawler/logger'
require_relative '../lib/ocr_crawler/memory_manager'
require_relative '../lib/ocr_crawler/initializer'
require_relative '../lib/ocr_crawler/document_processor'
require_relative '../lib/ocr_crawler/downloader'
require_relative '../lib/ocr_crawler/ffmpeg_helper'
require_relative '../lib/ocr_crawler/ocr_executor'
require_relative '../lib/ocr_crawler/image_manager'
require_relative '../lib/ocr_crawler/video_manager'
require_relative '../lib/ocr_crawler/link_manager'
require_relative '../lib/ocr_crawler/result_recorder'
require_relative '../lib/ocr_crawler/crawler'

# Usage:
#   ruby bin/run.rb [config_or_url] [max_depth]
# If first arg is a URL it overrides config start_urls; otherwise it is treated as config.yaml path.

arg1 = ARGV[0]
arg2 = ARGV[1]

# Determine config
if arg1 && arg1 =~ %r{\Ahttps?://}
  # load default config then override start_urls
  cfg = OCRCrawler::Config.load
  cfg[:start_urls] = [arg1]
else
  cfg_path = arg1 || File.join(Dir.pwd, 'config.yaml')
  cfg = OCRCrawler::Config.load(cfg_path)
end

cfg[:max_depth] = arg2.to_i if arg2

# Initialize environment
OCRCrawler::Initializer.setup

# Run crawler
crawler = OCRCrawler::Crawler.new(cfg)
crawler.run

# Post-processing: download resources + extract frames + OCR
results_file = File.join(cfg[:output_dir], 'results.json')
processed = []

if File.exist?(results_file)
  discovered = JSON.parse(File.read(results_file))
  discovered.each do |entry|
    type = (entry['type'] || entry[:type]).to_s
    page = entry['source_page'] || entry['page'] || entry['page_url'] || nil
    src = entry['url'] || entry['source'] || entry['src'] || nil
    next unless src

    case type
    when 'image', 'img'
      local = OCRCrawler::Downloader.download(src, 'images', cfg)
      text = ''
      text = OCRCrawler::OCRExecutor.perform(local) if local && File.exist?(local)
      processed << OCRCrawler::ResultRecorder.build(page, 'image', src, local, text)
    when 'video'
      local = OCRCrawler::Downloader.download(src, 'videos', cfg)
      if local && File.exist?(local)
        frames_dir = OCRCrawler::FFmpegHelper.extract_frames(local, cfg)
        # OCR each frame and append entries
        OCRCrawler::OCRExecutor.batch_from_frames(frames_dir, page, src, processed) if frames_dir
      end
      # also save a record for the video file itself
      processed << OCRCrawler::ResultRecorder.build(page, 'video', src, local, '')
    else
      # unknown type: keep as discovered
      processed << entry
    end
    OCRCrawler::MemoryManager.cleanup_file(local) unless cfg[:keep_files] || local.nil?
  end

  # Save processed results
  FileUtils.mkdir_p(cfg[:output_dir])
  out_file = File.join(cfg[:output_dir], 'processed_results.json')
  File.write(out_file, JSON.pretty_generate(processed))
  puts "Processed results written to #{out_file}"
else
  puts "No results.json found at #{results_file}; nothing to post-process."
end
