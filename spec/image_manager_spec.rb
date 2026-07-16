# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe OCRCrawler::ImageManager do
  subject(:manager) { described_class.new(config) }

  let(:config) do
    { selectors: { images: ['img', 'div.picture'] } }
  end

  describe '#extract' do
    it 'finds images from configured selectors' do
      html = '<html><body><img src="https://example.com/photo.jpg"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results.size).to eq(1)
      expect(results[0][:type]).to eq(:image)
      expect(results[0][:url]).to eq('https://example.com/photo.jpg')
      expect(results[0][:source_page]).to eq('https://example.com/')
    end

    it 'checks data-original before src' do
      html = '<html><body><img src="https://example.com/src.jpg" data-original="https://example.com/original.jpg"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results[0][:url]).to eq('https://example.com/original.jpg')
    end

    it 'falls back through src, data-src, content, href' do
      html = '<html><body><img content="https://example.com/content.jpg"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results[0][:url]).to eq('https://example.com/content.jpg')
    end

    it 'resolves relative URLs' do
      html = '<html><body><img src="/images/foo.png"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/sub/')
      expect(results[0][:url]).to eq('https://example.com/images/foo.png')
    end

    it 'filters out non-http/https URLs' do
      html = '<html><body><img src="data:image/png;base64,abc"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results).to be_empty
    end

    it 'deduplicates results by URL' do
      html = '<html><body><img src="https://example.com/dup.jpg"><img src="https://example.com/dup.jpg"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results.size).to eq(1)
    end

    it 'handles CSS selector errors gracefully' do
      bad_config = { selectors: { images: ['!!!invalid'] } }
      mgr = described_class.new(bad_config)
      doc = Nokogiri::HTML('<html></html>')
      expect { mgr.extract(doc, 'https://example.com/') }.not_to raise_error
    end

    it 'returns empty array when no selectors match' do
      doc = Nokogiri::HTML('<html><body><p>no images</p></body></html>')
      results = manager.extract(doc, 'https://example.com/')
      expect(results).to eq([])
    end
  end
end
