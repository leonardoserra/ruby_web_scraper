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
  if system('bundle show rubocop > NUL 2>&1') || system('bundle show rubocop > /dev/null 2>&1')
    sh 'bundle exec rubocop'
  else
    puts 'RuboCop not available. Run `bundle install` to enable linting.'
  end
end

desc 'Generate YARD documentation'
task :docs do
  if system('bundle show yard > NUL 2>&1') || system('bundle show yard > /dev/null 2>&1')
    sh 'bundle exec yard doc'
  else
    puts 'YARD not available. Run `bundle install` to enable docs generation.'
  end
end

desc 'Clean output and temporary files'
task :clean do
  FileUtils.rm_rf(OUTPUT_DIR)
  puts "Removed #{OUTPUT_DIR}/"
end

desc 'Run the OCR Web Crawler'
task :run, [:url, :max_depth, :config] do |_, args|
  url = args[:url]
  max_depth = args[:max_depth]
  config_path = args[:config] || File.join(Dir.pwd, 'config.yaml')

  cmd_parts = []
  cmd_parts << 'ruby bin/run.rb'
  cmd_parts << config_path unless url && url =~ %r{\Ahttps?://}
  cmd_parts << url if url
  cmd_parts << max_depth if max_depth

  cmd = cmd_parts.join(' ')
  puts "Executing: #{cmd}"
  sh cmd
end

desc 'Default: Run lint and tests'
task default: %i[lint spec]
