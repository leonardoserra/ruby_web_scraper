# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe OCRCrawler::VideoManager do
  subject(:manager) { described_class.new(config) }

  let(:config) do
    { selectors: { videos: ['video', '[data-video]'] } }
  end

  describe '#extract' do
    it 'finds videos from configured selectors' do
      html = '<html><body><video src="https://example.com/movie.mp4"></video></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results.size).to eq(1)
      expect(results[0][:type]).to eq(:video)
      expect(results[0][:url]).to eq('https://example.com/movie.mp4')
      expect(results[0][:source_page]).to eq('https://example.com/')
    end

    it 'checks src, data-src, content, href, poster in order' do
      html = '<html><body><video poster="https://example.com/poster.jpg" src="https://example.com/vid.mp4"></video></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results[0][:url]).to eq('https://example.com/vid.mp4')
    end

    it 'falls back to poster when src is absent' do
      html = '<html><body><video poster="https://example.com/poster.jpg"></video></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results[0][:url]).to eq('https://example.com/poster.jpg')
    end

    it 'resolves relative URLs' do
      html = '<html><body><video src="/videos/clip.mp4"></video></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results[0][:url]).to eq('https://example.com/videos/clip.mp4')
    end

    it 'filters non-http/https URLs' do
      html = '<html><body><video src="ftp://example.com/vid.mp4"></video></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results).to be_empty
    end

    it 'returns empty array when no selectors match' do
      doc = Nokogiri::HTML('<html><body><p>no videos</p></body></html>')
      results = manager.extract(doc, 'https://example.com/')
      expect(results).to eq([])
    end

    it 'deduplicates results by URL' do
      html = '<html><body><video src="https://example.com/dup.mp4"></video><video src="https://example.com/dup.mp4"></video></body></html>'
      doc = Nokogiri::HTML(html)
      results = manager.extract(doc, 'https://example.com/')
      expect(results.size).to eq(1)
    end

    it 'handles CSS selector errors gracefully' do
      bad_config = { selectors: { videos: ['!!!invalid'] } }
      mgr = described_class.new(bad_config)
      doc = Nokogiri::HTML('<html></html>')
      expect { mgr.extract(doc, 'https://example.com/') }.not_to raise_error
    end
  end
end
