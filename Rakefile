# frozen_string_literal: true

require 'rake'
require 'fileutils'

APP_NAME = 'ruby_ocr_crawler'
OUTPUT_DIR = 'output'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts 'RSpec not available. Run `bundle install` if you want to enable testing.'
end

desc 'Run Rubocop to check for code style issues'
task :lint do
  sh 'bundle exec rubocop'
end

desc 'Generate YARD documentation'
task :docs do
  sh 'bundle exec yard doc'
end

desc 'Clean output and temporary files'
task :clean do
  FileUtils.rm_rf(OUTPUT_DIR)
  FileUtils.mkdir_p(OUTPUT_DIR)
  puts "Cleaned #{OUTPUT_DIR} directory."
end

desc 'Run the OCR Web Crawler'
task :run, [:url] do |_, args|
  url = args[:url] || 'https://example.com'
  puts "Starting crawl for: #{url}"
  sh "bundle exec ruby bin/run.rb #{url}"
end

desc 'Default: Run lint and tests'
task default: %i[lint spec]
