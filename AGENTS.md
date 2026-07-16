# AGENTS.md — ruby_web_scraper

## Quick start

```bash
bundle install                           # Ruby >= 3.3.7
# System deps: tesseract-ocr + ffmpeg must be on PATH
bundle exec rspec                        # run tests
bundle exec rubocop                      # lint (120-char lines, LF endings)
bundle exec yard doc                     # generate docs
rake default                             # lint + spec (order matters: lint first)
```

## Running the crawler

- **Via Rake:** `bundle exec rake "run[https://example.com,2]"` — args: url (overrides config), max_depth, config_path
- **Direct:** `ruby bin/run.rb [config_path|url] [max_depth]`
- **Docker:** `docker compose up --build` then `docker compose run --rm ocr_crawler rake "run[url,2]"`

`config.yaml` is **gitignored** — copy `example.config.yaml` to start.

## Architecture

| Layer | Entry / ownership |
|---|---|
| Library entry | `lib/ocr_crawler.rb` → `OCRCrawler.run` |
| CLI script | `bin/run.rb` — loads config, runs `Crawler#run`, then post-processes (download + FFmpeg frames + OCR) |
| Config | `Config.load(path)` caches after first call (module-level `@config`). Symbolizes keys, merges with defaults. |
| Crawl | `Crawler` — thread-pool (`Queue` + `Set` + mutexes), delegates to `ImageManager`, `VideoManager`, `LinkManager`, `DocumentProcessor` |
| Output | `output/results.json` (discovered), `output/processed_results.json` (after download/OCR) |
| Memory | `MemoryManager` triggers `GC.start` every `gc_interval` pages |

### Key quirk: config caching

`OCRCrawler::Config.load` caches its return value — subsequent calls return the same hash without reloading the file. In tests, clear it (e.g., `OCRCrawler::Config.instance_variable_set(:@config, nil)`) or require files in the right order.

### Post-processing lives in `bin/run.rb`, not in the library

The library (`lib/`) handles crawling only. Download, FFmpeg frame extraction, and OCR execution are orchestrated in `bin/run.rb` after `Crawler#run` returns. If you use `OCRCrawler.run` from outside `bin/run.rb`, you get crawl-only behavior.

## Testing

- **Framework:** RSpec (`--format documentation`), 49 examples across 9 spec files
- **HTTP recording:** VCR + WebMock (`record: :new_episodes`); cassettes in `spec/fixtures/vcr_cassettes/`
- **Single spec:** `bundle exec rspec spec/crawler_spec.rb`
- **Network error tests** connect to `nonexistent.invalid` (RFC 2606); no cassette needed
- Config cache is cleared between examples (`after(:each)` hook in `spec_helper.rb`)
- Default rake task runs `lint` then `spec` — fix lint before running tests.

## Conventions

- RuboCop NewCops enabled, 120-char line limit, LF line endings
- VCR cassettes (if used) go in `spec/fixtures/vcr_cassettes/`
- `frozen_string_literal: true` on every file (not yet enforced by config but established practice)
