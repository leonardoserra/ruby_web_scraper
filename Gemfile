# frozen_string_literal: true

source "https://rubygems.org"

# ------------------------------
# Project Metadata
# ------------------------------
# Name: ruby_ocr_crawler
# Purpose: Web Crawler with OCR for images and videos.
# Author: Leonardo Serra
# Ruby Version: >= 3.1
ruby ">= 3.1"

gem "httparty", "~> 0.21"
gem "nokogiri", "~>1.16"
gem "rtesseract", "~> 3.1"
gem "mini_magick", "~> 4.12"
gem "logger", "~> 1.6"
gem "tty-progressbar", "~> 0.18"


group :development, :test do
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rspec", require: false
  gem "rspec", "~> 3.12"
  gem "webmock", "~> 3.20"
  gem "vcr", "~> 6.3"
end

gem "yard", "~> 0.9", require: false