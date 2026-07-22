# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe OCRCrawler::OCRExecutor do
  before(:each) do
    described_class.instance_variable_set(:@tesseract_available, nil)
  end

  describe '.tesseract_available?' do
    it 'returns true or false' do
      result = described_class.tesseract_available?
      expect([true, false]).to include(result)
    end

    it 'caches the result' do
      first = described_class.tesseract_available?
      second = described_class.tesseract_available?
      expect(first).to eq(second)
    end
  end

  describe '.perform' do
    it 'returns empty string when file does not exist' do
      result = described_class.perform('/nonexistent/path.jpg')
      expect(result).to eq('')
    end

    it 'does not raise when tesseract is unavailable' do
      allow(described_class).to receive(:tesseract_available?).and_return(false)
      expect { described_class.perform('/nonexistent.jpg') }.not_to raise_error
    end
  end

  describe '.batch_from_frames' do
    it 'iterates frame files and appends results', :vcr do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'frame_0001.jpg'), 'fake image data')
        results = []
        described_class.batch_from_frames(dir, 'https://page.com', 'https://video.com', results)
        expect(results.size).to eq(1)
        expect(results[0][:source_page]).to eq('https://page.com')
        expect(results[0][:type]).to eq(:video_frame)
        expect(results[0][:url]).to eq('https://video.com')
        expect(results[0][:path]).to match(/frame_0001\.jpg$/)
      end
    end

    it 'does nothing when directory has no jpg files' do
      Dir.mktmpdir do |dir|
        results = []
        described_class.batch_from_frames(dir, 'https://page.com', 'https://video.com', results)
        expect(results).to be_empty
      end
    end
  end
end
