# ruby_web_scraper — Session Context

## Branch
`fix/code-review-issues`

## Phase completed
**Code review fixes + behavioral tests** — committed to branch.
- 49 RSpec tests, 0 failures
- RuboCop clean (0 offenses)
- YARD docs generated

## Current phase
**GUI + Site model + JSON config** — in progress.

### Decisions
| Decision | Choice |
|---|---|
| GUI toolkit | Glimmer DSL for LibUI (zero prerequisites) |
| Config format | JSON (`config.json`), cold turkey — no YAML fallback |
| Per-site model | `Site` data class with own url, max_depth, media_selectors, link_selectors |
| Media type | Unified `media_selectors` (no separate image/video) |

### Plan steps (remaining)

- [ ] **1. Site data class** — `lib/ocr_crawler/site.rb`
- [ ] **2. Config refactor** — read/write `config.json`, `sites:` array, Site objects
- [ ] **3. MediaManager** — merge ImageManager + VideoManager into unified media extraction
- [ ] **4. LinkManager** — accept optional `link_selectors:` param
- [ ] **5. Crawler** — thread per-site selectors through queue
- [ ] **6. Gem** — add `glimmer-dsl-libui`
- [ ] **7. Config serializer** — `lib/ocr_crawler/gui/config_serializer.rb`
- [ ] **8. Main window** — `lib/ocr_crawler/gui/application.rb`
- [ ] **9. Site form** — `lib/ocr_crawler/gui/site_form.rb` (multiline text areas)
- [ ] **10. Site table** — `lib/ocr_crawler/gui/site_table.rb`
- [ ] **11. Global panel** — `lib/ocr_crawler/gui/config_panel.rb`
- [ ] **12. Runner** — `lib/ocr_crawler/gui/runner.rb` (subprocess)
- [ ] **13. Launcher** — `bin/gui.rb`
- [ ] **14. Example config** — `example.config.json`
- [ ] **15. Tests** — site_spec, media_manager_spec, config_spec update, etc.
- [ ] **16. Cleanup** — remove example.config.yaml, update AGENTS.md, .gitignore

### Files created this phase
```
lib/ocr_crawler/site.rb
lib/ocr_crawler/media_manager.rb
lib/ocr_crawler/gui/
  application.rb
  site_form.rb
  site_table.rb
  config_panel.rb
  config_serializer.rb
  runner.rb
bin/gui.rb
example.config.json
```

### Files modified this phase
```
lib/ocr_crawler/config.rb
lib/ocr_crawler/crawler.rb
lib/ocr_crawler/link_manager.rb
bin/run.rb
.gitignore
AGENTS.md
Gemfile → add glimmer-dsl-libui
```

### Files removed this phase
```
example.config.yaml
```

### Key architecture notes
- `Config.load` reads `config.json`, returns hash with symbolized keys + `sites:` as array of `Site` objects
- Queue jobs carry `{ url:, depth:, media_selectors:, link_selectors: }` instead of just `{ url:, depth: }`
- `MediaManager.extract(doc, base_url, selectors)` replaces `ImageManager.extract` / `VideoManager.extract`
- `LinkManager.enqueue_links(doc, base_url, depth, selectors)` uses custom selectors (defaults to `a[href]`)
- GUI writes `config.json` after any edit — always in a valid state
- `bin/run.rb` defaults to `config.json` instead of `config.yaml`
