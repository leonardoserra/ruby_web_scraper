# frozen_string_literal: true

require 'spec_helper'
RSpec.describe OCRCrawler::ImageManager do
  it 'constructs' do
    config = OCRCrawler::Config.load
    expect { OCRCrawler::ImageManager.new(config) }.not_to raise_error
  end
end
