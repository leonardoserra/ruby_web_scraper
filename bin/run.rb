#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ocr_crawler'

OCRCrawler::Initializer.setup
config = OCRCrawler::Config.load
OCRCrawler::Crawler.new(config).run
