# frozen_string_literal: true

require 'spec_helper'
RSpec.describe 'Crawler integration' do
  it 'initializes without error' do
    expect { OCRCrawler::Initializer.setup }.not_to raise_error
  end
end
