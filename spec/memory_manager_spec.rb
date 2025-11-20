# frozen_string_literal: true

require 'spec_helper'
RSpec.describe OCRCrawler::MemoryManager do
  it 'responds to cleanup' do
    expect(OCRCrawler::MemoryManager).to respond_to(:cleanup)
  end
end
