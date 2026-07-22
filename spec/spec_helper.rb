# frozen_string_literal: true

require 'bundler/setup'
require 'ocr_crawler'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    OCRCrawler::Config.reset_cache!
  end

  config.after(:each) do
    OCRCrawler::Config.reset_cache!
  end
end
