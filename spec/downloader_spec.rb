# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe OCRCrawler::Downloader do
  let(:config) { { output_dir: Dir.mktmpdir, user_agent: 'test-agent/1.0' } }

  after(:each) do
    FileUtils.rm_rf(config[:output_dir])
  end

  describe '.download' do
    it 'downloads a resource and returns local path', :vcr do
      path = described_class.download('https://example.com/', 'images', config)
      expect(path).not_to be_nil
      expect(File.exist?(path)).to be(true)
      expect(path).to match(%r{images/})
    end

    it 'returns nil on HTTP error', :vcr do
      path = described_class.download('https://httpbin.org/status/404', 'images', config)
      expect(path).to be_nil
    end

    it 'returns nil on network error' do
      path = described_class.download('https://nonexistent.invalid/file', 'images', config)
      expect(path).to be_nil
    end

    it 'creates the subfolder under output_dir', :vcr do
      path = described_class.download('https://example.com/', 'custom_sub', config)
      expect(path).to match(%r{custom_sub/})
    end

    it 'sets User-Agent from config on the HTTP request' do
      uri = URI.parse('https://example.com/file.jpg')
      req = described_class.send(:build_request, uri, { user_agent: 'my-agent/1.0' })
      expect(req['User-Agent']).to eq('my-agent/1.0')
    end

    it 'uses default User-Agent when config has none' do
      uri = URI.parse('https://example.com/file.jpg')
      req = described_class.send(:build_request, uri, {})
      expect(req['User-Agent']).to eq('ruby-ocr-crawler/1.0')
    end
  end
end
