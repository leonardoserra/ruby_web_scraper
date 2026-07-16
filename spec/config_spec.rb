# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tmpdir'

RSpec.describe OCRCrawler::Config do
  around(:each) do |example|
    described_class.reset_cache!
    example.run
    described_class.reset_cache!
  end

  describe '.load' do
    it 'loads JSON and symbolizes keys' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.json')
        File.write(path, JSON.generate({ 'threads' => 2, 'sites' => [{ 'url' => 'https://example.com' }] }))
        cfg = described_class.load(path)
        expect(cfg[:threads]).to eq(2)
        expect(cfg[:sites].first).to be_a(OCRCrawler::Site)
        expect(cfg[:sites].first.url).to eq('https://example.com')
      end
    end

    it 'merges with defaults' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.json')
        File.write(path, JSON.generate({}))
        cfg = described_class.load(path)
        expect(cfg[:gc_interval]).to eq(100)
        expect(cfg[:threads]).to eq(4)
      end
    end

    it 'returns defaults when file does not exist' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'nonexistent.json')
        cfg = described_class.load(path)
        expect(cfg[:threads]).to eq(4)
        expect(cfg[:keep_files]).to be(false)
      end
    end

    it 'returns cached result on subsequent calls' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.json')
        File.write(path, JSON.generate({ 'threads' => 8 }))
        first = described_class.load(path)
        File.write(path, JSON.generate({ 'threads' => 2 }))
        second = described_class.load(path)
        expect(first[:threads]).to eq(8)
        expect(second[:threads]).to eq(8)
      end
    end

    it 'builds Site objects from sites array' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.json')
        data = {
          'sites' => [
            { 'url' => 'https://a.com', 'max_depth' => 3, 'media_selectors' => ['img'], 'link_selectors' => ['a'] },
            { 'url' => 'https://b.com' }
          ]
        }
        File.write(path, JSON.generate(data))
        cfg = described_class.load(path)
        expect(cfg[:sites].size).to eq(2)
        expect(cfg[:sites][0].max_depth).to eq(3)
        expect(cfg[:sites][1].max_depth).to eq(1)
        expect(cfg[:start_urls]).to eq(['https://a.com', 'https://b.com'])
      end
    end

    it 'handles empty file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.json')
        File.write(path, '')
        expect { described_class.load(path) }.not_to raise_error
      end
    end
  end

  describe '.reset_cache!' do
    it 'clears the cached config' do
      path = File.join(Dir.mktmpdir, 'config.json')
      File.write(path, JSON.generate({ 'threads' => 8 }))
      described_class.load(path)
      described_class.reset_cache!
      File.write(path, JSON.generate({ 'threads' => 3 }))
      cfg = described_class.load(path)
      expect(cfg[:threads]).to eq(3)
    end
  end
end
