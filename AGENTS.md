# AGENTS.md — ruby_web_scraper

## Quick start

```bash
bundle install                           # Ruby >= 3.3.7
# System deps: tesseract-ocr + ffmpeg must be on PATH
bundle exec rspec                        # run tests (60 examples)
bundle exec rubocop                      # lint (120-char lines, LF endings)
bundle exec yard doc                     # generate docs
rake default                             # lint + spec (order matters: lint first)
```

## Running the crawler

- **With GUI:** `ruby bin/gui.rb` — desktop window to manage sites, selectors, and run
- **Via Rake:** `bundle exec rake "run[https://example.com,2]"` — args: url (overrides config), max_depth, config_path
- **Direct:** `ruby bin/run.rb [config_path|url] [max_depth]`
- **Docker (CLI):** `docker compose up --build` then `docker compose run --rm ocr_crawler rake "run[url,2]"`
- **Docker GUI (cross-platform):** `ruby bin/docker-gui.rb` — detects OS, installs prerequisites, and launches the GUI via Docker (Linux X11, macOS XQuartz, Windows WSLg/VcXsrv)
- **Tor IP rotation:** The container auto-starts Tor + Privoxy. Set `tor_circuit_interval: 3` in `config.json` to rotate IP every 3 requests.

Config is in `config.json` (gitignored). Copy `example.config.json` to start.

## Architecture

| Layer | Entry / ownership |
|---|---|
| Library entry | `lib/ocr_crawler.rb` → `OCRCrawler.run` |
| GUI app | `bin/gui.rb` → `OCRCrawler::GUI::Application` (Glimmer DSL for LibUI) |
| CLI script | `bin/run.rb` — loads config, runs `Crawler#run`, then post-processes |
| Config | `Config.load(path)` reads `config.json`, caches after first call |
| Crawl | `Crawler` — thread-pool, delegates to `MediaManager`, `LinkManager`, `DocumentProcessor` |
| Site model | `OCRCrawler::Site` — value object with url, max_depth, media_selectors, link_selectors |
| Output | `output/results.json` (discovered), `output/processed_results.json` (after download/OCR) |
| Network | `HTTPClient` — unified HTTP fetching with optional proxy; auto-detects Privoxy at `127.0.0.1:8118` |
| Tor | `TorManager` — connects to Tor control port via cookie auth, sends `SIGNAL NEWNYM` for circuit rotation |

### Config caching

`Config.load` caches its return value. Call `Config.reset_cache!` to force reload (used in tests).

### Post-processing lives in `bin/run.rb` / GUI

The library handles crawling only. Download, FFmpeg frame extraction, and OCR are orchestrated by `bin/run.rb` or the GUI's `Application#run_crawler`. `OCRCrawler.run` gives crawl-only behavior.

### Depth enforcement

The `LinkManager` enforces per-site `max_depth` by forwarding the job's `max_depth` (and `media_selectors`, `link_selectors`) via an `extra` hash when enqueueing discovered links. This ensures child jobs carry their parent site's config — they don't fall back to the global default.

## Per-site selectors

Each site has its own:
- `media_selectors` — CSS selectors to find media (images, videos, or anything with src/data-src/poster)
- `link_selectors` — CSS selectors to find links to follow per depth level

Media extraction unified under `MediaManager` (replaces separate ImageManager/VideoManager).

## Testing

- **Framework:** RSpec (`--format documentation`), 60 examples across 12 spec files
- **HTTP recording:** VCR + WebMock (`record: :new_episodes`); cassettes in `spec/fixtures/vcr_cassettes/`
- **Single spec:** `bundle exec rspec spec/crawler_spec.rb`
- **Network error tests** connect to `nonexistent.invalid` (RFC 2606); no cassette needed
- Config cache cleared between examples (`after(:each)` in `spec_helper.rb`)
- Default rake task runs `lint` then `spec` — fix lint before running tests.

## Conventions

- RuboCop NewCops enabled, 120-char line limit, LF line endings
- VCR cassettes in `spec/fixtures/vcr_cassettes/`
- `frozen_string_literal: true` on every file
- `bin/gui.rb` requires glimmer-dsl-libui (zero prerequisites)
- commit and push only if required by the user.
- don't exit from this root folder.
