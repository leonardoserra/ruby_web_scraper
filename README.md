# Ruby OCR Crawler

A modular, memory-safe Ruby web crawler that discovers images and videos from web pages, downloads media, extracts video frames via FFmpeg, and performs OCR on images/frames using Tesseract. Selector-driven via per-site `config.json` — target specific HTML tags or attributes per domain.

---

## Table of contents

- Requirements
- Install
- Setup (`config.json`)
- Running the crawler
- Docker
- Tor IP rotation
- Output layout
- Testing & linting
- Architecture
- Troubleshooting
- License

---

## Requirements

- Ruby 3.1+ (tested on 3.4.8)
- Bundler
- Tesseract OCR (`tesseract` on PATH) — required for OCR
- FFmpeg (`ffmpeg` on PATH) — required for video frame extraction
- Optional: Docker + Docker Compose for containerized runs with Tor

---

## Install

```bash
git clone <repo-url> && cd ruby_web_scraper
bundle install
```

System packages (select your platform):

| Platform | Command |
|---|---|
| macOS (Homebrew) | `brew install tesseract ffmpeg` |
| Debian / Ubuntu | `sudo apt install -y tesseract-ocr ffmpeg` |
| Fedora / RHEL | `sudo dnf install -y tesseract ffmpeg` |
| Windows | `winget install --id=Gyan.FFmpeg` (Tesseract: manual PATH setup) |

Verify:
```bash
tesseract --version && ffmpeg -version
```

---

## Setup (`config.json`)

Copy `example.config.json` to `config.json` and adapt. The config uses a per-site model:

```json
{
  "sites": [
    {
      "url": "https://example.com",
      "max_depth": 2,
      "media_selectors": ["img", "video", "a.popupImage[href]"],
      "link_selectors": ["a[href]", ".collection-title-details a[href]"]
    }
  ],
  "threads": 4,
  "output_dir": "output",
  "frame_rate": 1,
  "gc_interval": 100,
  "keep_files": false,
  "user_agent": "ruby-ocr-crawler/1.0",
  "proxy": null,
  "tor_circuit_interval": 0
}
```

### Per-site fields

| Field | Description |
|---|---|
| `url` | Start URL for this site |
| `max_depth` | Maximum crawl depth (0 = seed page only) |
| `media_selectors` | CSS selectors to find media elements (extracts from `src`, `data-src`, `data-original`, `href`, `poster`, `content`) |
| `link_selectors` | CSS selectors to find links to follow (defaults to `a[href]`) |

### Global fields

| Field | Default | Description |
|---|---|---|
| `threads` | `4` | Number of worker threads |
| `output_dir` | `./output` | Output directory for results and downloads |
| `frame_rate` | `1` | FFmpeg frame extraction rate (fps) |
| `gc_interval` | `100` | Trigger GC every N pages |
| `keep_files` | `false` | Keep downloaded files after OCR |
| `user_agent` | `ruby-ocr-crawler/1.0` | HTTP User-Agent header |
| `proxy` | `null` | HTTP proxy URL (auto-detects Privoxy at `127.0.0.1:8118`) |
| `tor_circuit_interval` | `0` | Rotate Tor circuit every N requests (0 = disabled) |

---

## Running the crawler

### Desktop GUI

```bash
ruby bin/gui.rb
```

A Glimmer DSL for LibUI window to manage sites, edit selectors, and run crawls interactively.

### Docker GUI (cross-platform)

```bash
ruby bin/docker-gui.rb
```

Detects Linux (X11), macOS (XQuartz + socat), or Windows (WSLg/VcXsrv) and launches the GUI inside a Docker container with Tor + Privoxy.

### CLI (Rake)

```bash
bundle exec rake "run[https://example.com,2]"
```

Arguments: URL (overrides config), max_depth. Uses `config.json` by default.

### CLI (direct)

```bash
ruby bin/run.rb                    # uses config.json
ruby bin/run.rb config.json        # explicit config path
ruby bin/run.rb https://example.com 2  # URL + max_depth override
```

### Docker CLI

```bash
docker compose up --build
docker compose run --rm ocr_crawler rake "run[https://example.com,2]"
```

---

## Docker

The Docker image (`ruby:3.4.8-trixie`) bundles:
- Tesseract OCR
- FFmpeg
- Tor + Privoxy
- GTK3 (for GUI mode)

Build and run:

```bash
docker compose up --build
docker compose run --rm ocr_crawler rake "run[https://example.com,2]"
```

The entry point (`docker-entrypoint.sh`) starts Tor and Privoxy in the background before running the CMD. Output files mount from `./output` on the host.

---

## Tor IP rotation

The container auto-starts Tor (SOCKS5 on `:9050`) and Privoxy (HTTP proxy on `:8118`). `HTTPClient` auto-detects Privoxy at `127.0.0.1:8118`.

Set `tor_circuit_interval: 3` in `config.json` to rotate the Tor circuit every 3 HTTP requests. `TorManager` connects to the Tor control port (`:9051`) via cookie authentication and sends `SIGNAL NEWNYM`.

---

## Output layout

```
output/
├── images/              # downloaded images
├── videos/              # downloaded video files
├── video_frames/        # FFmpeg-extracted frames (per video subdirectory)
├── results.json         # discovered resources (pre-processing)
└── processed_results.json  # after download + OCR
```

Result entry format:

```json
{
  "source_page": "https://example.com",
  "type": "image",
  "url": "https://example.com/img.jpg",
  "path": "output/images/abc123_img.jpg",
  "text": "OCR text content"
}
```

- `results.json` — `path` and `text` are `null` (crawl only)
- `processed_results.json` — `path` and `text` filled by `bin/run.rb` or the GUI

---

## Testing & linting

```bash
bundle exec rspec          # 60 examples, --format documentation
bundle exec rubocop        # 37 files, 0 offenses (120-char, LF)
rake default               # lint → spec (order matters)
```

VCR cassettes in `spec/fixtures/vcr_cassettes/`. Network error tests use `nonexistent.invalid` (RFC 2606). Config cache is reset between examples.

---

## Architecture

```
bin/
├── gui.rb               # desktop GUI launcher (Glimmer DSL for LibUI)
├── docker-gui.rb         # cross-platform Docker GUI launcher
├── run.rb                # CLI entry: crawl + download + OCR

lib/ocr_crawler/
├── site.rb               # per-site value object (url, depth, selectors)
├── config.rb             # JSON config loader (cached, reset_cache!)
├── initializer.rb        # runtime setup (directories, GC, logging)
├── logger.rb             # simple class-level Logger wrapper
├── crawler.rb            # main orchestration (thread pool, queue)
├── link_manager.rb       # link extraction & depth enforcement
├── media_manager.rb      # unified media extraction (CSS selectors)
├── image_manager.rb      # image-specific extraction (legacy)
├── video_manager.rb      # video-specific extraction (legacy)
├── downloader.rb         # HTTP download via HTTPClient
├── document_processor.rb # page fetching via HTTPClient
├── http_client.rb        # unified HTTP fetch with proxy/Tor support
├── tor_manager.rb        # Tor circuit rotation (control port cookie auth)
├── ffmpeg_helper.rb      # video frame extraction
├── ocr_executor.rb       # Tesseract OCR via RTesseract
├── result_recorder.rb    # JSON result persistence
├── memory_manager.rb     # periodic GC trigger + file cleanup

gui/
├── application.rb        # main GUI window (sites table, run, output)
├── config_serializer.rb  # GUI-specific config read/write

docker-entrypoint.sh      # starts Tor + Privoxy, then CMD
Dockerfile                # Ruby 3.4.8 + Tesseract + FFmpeg + Tor + GTK3
```

### Depth enforcement

Each discovered link carries its parent site's `max_depth`, `media_selectors`, and `link_selectors` via an `extra` hash. The `LinkManager` checks `current_depth >= max_depth` and stops enqueuing when the limit is reached — child jobs never fall back to a global default.

### Network layer

`HTTPClient` wraps `Net::HTTP` and automatically detects Privoxy at `127.0.0.1:8118`. When a proxy is set, it uses `Net::HTTP::Proxy`. `TorManager` connects to Tor's control port (`127.0.0.1:9051`) using cookie authentication and issues `SIGNAL NEWNYM` for circuit rotation.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Media not downloaded | `media_selectors` empty or wrong — check `config.json` per-site |
| Crawl goes beyond max_depth | Old Docker image — rebuild with `docker compose build` |
| `EACCES` on output files | Docker container runs as root; host files owned by root |
| Tor warnings in log | Normal; Tor running as root inside container |
| "Failed to load module canberra-gtk-module" | Harmless GTK warning; suppressed via `GTK_MODULES=` env |
| Downloads fail | Adjust `user_agent` or check proxy settings |
| `output/` missing | Verify write permissions and `output_dir` in config |
| Tesseract/FFmpeg not found | Install system packages, verify PATH |

---

## License

MIT — see LICENSE file.
