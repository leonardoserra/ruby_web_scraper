# frozen_string_literal: true

require 'spec_helper'
require 'yaml'
require 'tmpdir'

RSpec.describe OCRCrawler::Config do
  around(:each) do |example|
    OCRCrawler::Config.instance_variable_set(:@config, nil)
    example.run
    OCRCrawler::Config.instance_variable_set(:@config, nil)
  end

  describe '.load' do
    it 'loads YAML and symbolizes keys' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.yaml')
        File.write(path, { 'start_urls' => ['https://example.com'], 'threads' => 2 }.to_yaml)
        cfg = described_class.load(path)
        expect(cfg[:start_urls]).to eq(['https://example.com'])
        expect(cfg[:threads]).to eq(2)
      end
    end

    it 'merges with defaults' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.yaml')
        File.write(path, {}.to_yaml)
        cfg = described_class.load(path)
        expect(cfg[:gc_interval]).to eq(100)
        expect(cfg[:selectors][:images]).to eq(['img'])
      end
    end

    it 'returns defaults when file does not exist' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'nonexistent.yaml')
        cfg = described_class.load(path)
        expect(cfg[:start_urls]).to eq(['https://example.com'])
        expect(cfg[:keep_files]).to be(false)
      end
    end

    it 'returns cached result on subsequent calls' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.yaml')
        File.write(path, { 'threads' => 8 }.to_yaml)
        first = described_class.load(path)
        File.write(path, { 'threads' => 2 }.to_yaml)
        second = described_class.load(path)
        expect(first[:threads]).to eq(8)
        expect(second[:threads]).to eq(8)
      end
    end

    it 'handles empty file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.yaml')
        File.write(path, '')
        expect { described_class.load(path) }.not_to raise_error
      end
    end
  end
end
