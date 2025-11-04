require 'spec_helper'
RSpec.describe OCRCrawler::VideoManager do
  it 'constructs' do
    config = OCRCrawler::Config.load
    expect { OCRCrawler::VideoManager.new(config) }.not_to raise_error
  end
end
