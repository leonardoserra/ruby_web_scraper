# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe OCRCrawler::LinkManager do
  let(:config) { { max_depth: 2 } }
  let(:queue) { Queue.new }
  let(:visited) { Set.new }
  let(:mutex) { Mutex.new }
  subject(:manager) { described_class.new(config, queue, visited, mutex) }

  describe '#enqueue_links' do
    it 'enqueues absolute URLs from anchor tags' do
      html = '<html><body><a href="https://other.com/page">link</a></body></html>'
      doc = Nokogiri::HTML(html)
      manager.enqueue_links(doc, 'https://base.com/', 0)
      expect(queue.size).to eq(1)
      job = queue.pop(true)
      expect(job[:url]).to eq('https://other.com/page')
      expect(job[:depth]).to eq(1)
    end

    it 'resolves relative hrefs to absolute' do
      html = '<html><body><a href="/relative/path">link</a></body></html>'
      doc = Nokogiri::HTML(html)
      manager.enqueue_links(doc, 'https://base.com/', 0)
      job = queue.pop(true)
      expect(job[:url]).to eq('https://base.com/relative/path')
    end

    it 'does not enqueue links beyond max_depth' do
      html = '<html><body><a href="https://other.com/page">link</a></body></html>'
      doc = Nokogiri::HTML(html)
      manager.enqueue_links(doc, 'https://base.com/', 2)
      expect(queue.size).to eq(0)
    end

    it 'does not enqueue already visited URLs' do
      visited.add('https://other.com/page')
      html = '<html><body><a href="https://other.com/page">link</a></body></html>'
      doc = Nokogiri::HTML(html)
      manager.enqueue_links(doc, 'https://base.com/', 0)
      expect(queue.size).to eq(0)
    end

    it 'handles nil depth gracefully' do
      html = '<html><body><a href="https://other.com/page">link</a></body></html>'
      doc = Nokogiri::HTML(html)
      expect { manager.enqueue_links(doc, 'https://base.com/', nil) }.not_to raise_error
      expect(queue.size).to eq(0)
    end

    it 'skips nodes without href' do
      html = '<html><body><a>no href</a></body></html>'
      doc = Nokogiri::HTML(html)
      manager.enqueue_links(doc, 'https://base.com/', 0)
      expect(queue.size).to eq(0)
    end

    it 'ignores href values that cannot be resolved' do
      html = '<html><body><a href="http://foo bar.com/path">invalid</a></body></html>'
      doc = Nokogiri::HTML(html)
      expect { manager.enqueue_links(doc, 'https://base.com/', 0) }.not_to raise_error
      expect(queue.size).to eq(0)
    end
  end
end
