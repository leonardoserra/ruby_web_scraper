# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OCRCrawler::DocumentProcessor do
  describe '.fetch' do
    it 'returns a Nokogiri document for a valid URL', :vcr do
      doc = described_class.fetch('https://example.com')
      expect(doc).to be_a(Nokogiri::HTML::Document)
      expect(doc.at_css('title')).not_to be_nil
    end

    it 'returns nil for an unreachable URL' do
      doc = described_class.fetch('https://nonexistent.invalid/')
      expect(doc).to be_nil
    end

    it 'returns nil for an invalid URI' do
      doc = described_class.fetch('')
      expect(doc).to be_nil
    end

    it 'passes User-Agent from config when provided' do
      config = { user_agent: 'test-agent/1.0' }
      uri_double = instance_double(URI::HTTP)
      expect(URI).to receive(:parse).with('https://example.com').and_return(uri_double)
      expect(uri_double).to receive(:read).with('User-Agent' => 'test-agent/1.0')
                                          .and_return('<html><body></body></html>')
      described_class.fetch('https://example.com', config)
    end
  end
end
