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
      response = instance_double(Net::HTTPSuccess, body: '<html><body></body></html>', is_a?: true)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      expect(OCRCrawler::HTTPClient).to receive(:fetch)
        .with('https://example.com', config)
        .and_return(response)
      result = described_class.fetch('https://example.com', config)
      expect(result).to be_a(Nokogiri::HTML::Document)
    end
  end
end
