# ruby_web_scraper — Session Context

## Branch
`fix/code-review-issues`

## Phases completed

### Phase 1 — Code review fixes
- User-Agent on DocumentProcessor, dead ivars removed, key unification, SecureRandom for filenames, OS-agnostic shell redirects, Config cache reset in tests
- 49 behavioral tests added (was 4)
- YARD docs generated

### Phase 2 — GUI + Site model + JSON config
- `OCRCrawler::Site` value object: url, max_depth, media_selectors, link_selectors
- Config switched from YAML to JSON (`config.json`), cold turkey
- `MediaManager` unifies image/video extraction via CSS selectors
- `LinkManager` accepts optional `link_selectors:` parameter
- `Crawler` threads per-site selectors through queue jobs
- `glimmer-dsl-libui` GUI with tabbed main window (Sites + Global Config)
- Add/Edit site dialog with multiline text areas for CSS selectors
- Save Config + Run Crawler buttons with live output log
- `bin/gui.rb` launcher
- 60 RSpec tests, 0 failures, RuboCop clean

## Key architecture

| Concept | Details |
|---|---|
| Config file | `config.json` (gitignored), loaded via `Config.load` / `ConfigSerializer` |
| Site model | `Site.new(url:, max_depth:, media_selectors:, link_selectors:)` with defaults |
| Media extraction | `MediaManager#extract(doc, base_url, selectors)` — checks `data-original` > `src` > `data-src` > `content` > `href` > `poster` |
| Link extraction | `LinkManager#enqueue_links(doc, base_url, depth, link_selectors:, site_max_depth:)` |
| Crawler queue | Jobs carry `{ url:, depth:, media_selectors:, link_selectors:, max_depth: }` |
| Post-processing | Download + OCR runs in `bin/run.rb` OR `GUI::Application#run_crawler` (not in library) |
| GUI | Glimmer DSL for LibUI — zero prerequisites, native look |

## File structure (new/changed)

```
lib/ocr_crawler/
├── site.rb                 # Site value object
├── media_manager.rb        # Unified media extraction
├── config.rb               # JSON config with Site objects
├── crawler.rb              # Per-site selectors through queue
├── link_manager.rb         # Accepts link_selectors param
└── gui/
    ├── application.rb      # Main window (tabbed, Glimmer)
    └── config_serializer.rb # JSON read/write
bin/
├── gui.rb                  # GUI launcher
└── run.rb                  # CLI (defaults to config.json)
example.config.json          # Sample config
```

## Commands

```
ruby bin/gui.rb                       # Launch GUI
ruby bin/run.rb                       # CLI crawl (uses config.json)
bundle exec rake "run[url,2]"         # Rake shortcut
bundle exec rspec                     # 60 examples
bundle exec rubocop                   # 0 offenses
```
