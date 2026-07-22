# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe OCRCrawler::MediaManager do
  subject(:manager) { described_class.new({}) }

  describe '#extract' do
    it 'finds elements from given CSS selectors' do
      html = '<html><body><img src="https://example.com/pic.jpg"></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/', ['img'])
      expect(results.size).to eq(1)
      expect(results[0][:type]).to eq(:media)
      expect(results[0][:url]).to eq('https://example.com/pic.jpg')
    end

    it 'checks data-original first, then src, data-src, content, href, poster' do
      html = '<img src="https://src.jpg" data-original="https://orig.jpg">'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/', ['img'])
      expect(results[0][:url]).to eq('https://orig.jpg')
    end

    it 'falls back through attribute chain' do
      html = '<video poster="https://poster.jpg"></video>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/', ['video'])
      expect(results[0][:url]).to eq('https://poster.jpg')
    end

    it 'handles multiple selectors' do
      html = '<img src="https://a.jpg"><video src="https://b.mp4"></video>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/', %w[img video])
      expect(results.size).to eq(2)
    end

    it 'resolves relative URLs' do
      html = '<img src="/images/foo.png">'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/sub/', ['img'])
      expect(results[0][:url]).to eq('https://example.com/images/foo.png')
    end

    it 'filters non-http/https URLs' do
      html = '<img src="data:image/png;base64,abc">'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/', ['img'])
      expect(results).to be_empty
    end

    it 'deduplicates results by URL' do
      html = '<img src="https://x.com/dup.jpg"><img src="https://x.com/dup.jpg">'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://x.com/', ['img'])
      expect(results.size).to eq(1)
    end

    it 'handles CSS selector errors gracefully' do
      doc = Nokogiri::HTML('<html></html>')
      expect { manager.extract(doc, 'https://example.com/', ['!!!invalid']) }.not_to raise_error
    end

    it 'returns empty array for no selectors' do
      doc = Nokogiri::HTML('<html><body><p>none</p></body></html>')
      expect(manager.extract(doc, 'https://example.com/', [])).to eq([])
    end
  end
end
