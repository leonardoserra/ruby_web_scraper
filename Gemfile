# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.3.7'

gem 'mini_magick', '~> 4.12'
gem 'nokogiri', '~> 1.16'
# RTesseract requires system tesseract installed
gem 'rtesseract', '~> 3.1'

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.12'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'solargraph', require: false
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.20'
end

gem 'yard', '~> 0.9', require: false

gem 'glimmer-dsl-libui', '~> 0.13.1'

# Required by glimmer-dsl-libui and rtesseract; removed from default gems in Ruby 3.4+
gem 'csv'
gem 'fiddle'
gem 'logger'
gem 'ostruct'
