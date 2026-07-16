# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tmpdir'

RSpec.describe OCRCrawler::ResultRecorder do
  describe '.build' do
    it 'creates a result hash with the correct keys' do
      result = described_class.build('https://page.com', :image, 'https://img.com', '/tmp/img.jpg', 'ocr text')
      expect(result).to eq({
                             source_page: 'https://page.com',
                             type: :image,
                             url: 'https://img.com',
                             path: '/tmp/img.jpg',
                             text: 'ocr text'
                           })
    end

    it 'accepts nil path and text' do
      result = described_class.build('https://page.com', :video, 'https://vid.com', nil, nil)
      expect(result[:path]).to be_nil
      expect(result[:text]).to be_nil
    end
  end

  describe '#save' do
    it 'writes results to JSON file' do
      Dir.mktmpdir do |dir|
        config = { output_dir: dir }
        recorder = described_class.new(config)
        results = [{ source_page: 'https://page.com', type: :image, url: 'https://img.com', path: nil, text: nil }]
        recorder.save(results)
        file = File.join(dir, 'results.json')
        expect(File.exist?(file)).to be(true)
        parsed = JSON.parse(File.read(file))
        expect(parsed).to be_an(Array)
        expect(parsed[0]['source_page']).to eq('https://page.com')
      end
    end
  end
end
