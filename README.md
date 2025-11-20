# Ruby OCR Crawler

A modular, memory-safe Ruby web crawler that discovers images and videos from web pages, downloads media, extracts video frames via FFmpeg, and performs OCR on images/frames using Tesseract (RTesseract). The crawler is selector-driven via a `config.yaml` file so you can target specific HTML tags or attributes.

---

## Table of contents

- Overview
- Requirements
- Install (macOS / Linux / Windows)
- Setup (project)
- Configuration (`config.yaml`)
- Running the crawler
- Example end-to-end run (download + frames + OCR)
- Output layout
- Testing & linting
- Troubleshooting
- Extending / Notes
- License

---

## Overview

This project performs a crawl starting from one or more start URLs, finds images and videos using configurable CSS selectors, records discovered items, downloads media, extracts frames using FFmpeg, and runs Tesseract OCR on images/frames. It is designed for long-running crawls: it uses threads, mutexes, and a MemoryManager to periodically trigger GC.

---

## Requirements

- Ruby 3.1 or newer
- Bundler
- Tesseract (system binary available in PATH) — required for OCR
- FFmpeg (system binary available in PATH) — required for video frame extraction
- Optional: Homebrew (macOS), apt (Debian/Ubuntu), dnf/yum (Fedora/CentOS), winget/choco (Windows) to install system packages

---

## Install

General (applies to all platforms):

1. Clone the repository:
   ```bash
   git clone <repo-url> && cd ruby_web_scraper
   ```

2. Install gems:
   ```bash
   bundle install
   ```

Platform-specific system package install:

- macOS (Homebrew)
  ```bash
  # install Homebrew if needed: https://brew.sh/
  brew install tesseract ffmpeg
  ```

- Debian / Ubuntu
  ```bash
  sudo apt update
  sudo apt install -y ruby-full build-essential tesseract-ocr ffmpeg
  ```

- Fedora / RHEL / CentOS
  ```bash
  sudo dnf install -y ruby rubygems tesseract ffmpeg
  ```

- Windows (PowerShell) — using winget (Windows 10/11)
  ```powershell
  winget install --id=Gyan.FFmpeg
  # For Tesseract use an available package or installer; ensure tesseract.exe is on PATH.
  ```

Verify installation:
```bash
tesseract --version
ffmpeg -version
```

---

## Setup (project)

1. Ensure dependencies installed (see above).
2. Create or edit `config.yaml` at project root. A sample `example.config.yaml` is included in the repository and can be adapted.

Example fields:

- `start_urls`: array of seed URLs to crawl.
- `threads`: number of worker threads.
- `output_dir`: where downloaded media, frames and results are stored.
- `frame_rate`: fps used by FFmpeg when extracting frames from video.
- `gc_interval`: how many pages processed per GC trigger (MemoryManager).
- `max_depth`: maximum crawl depth from start URL.
- `keep_files`: true | false, choose if the files downloaded are saved on disk or deleted.
- `selectors.images`: CSS selectors used to find images (nodes should have `src`, `data-src`, `content`, or `href`).
- `selectors.videos`: CSS selectors used to find video resources (nodes should have `src`, `data-src`, `poster`, etc).
- `user_agent`: optional HTTP User-Agent header used by downloads.

---

## Running the crawler

There are two primary ways:

1. Rake task:
   ```bash
   # Run crawler; provide optional start URL and max depth:
   rake "run[https://example.com,2]"
   ```
   The `run` task accepts optional arguments: first is a start URL (overrides config), second is `max_depth`.

2. Direct script:
   ```bash
   ruby bin/run.rb path/to/config.yaml
   ```
   Or provide a URL and optional max depth directly:
   ```bash
   ruby bin/run.rb https://example.com 2
   ```

The script loads `config.yaml` (or merges CLI-provided URL), initializes the environment, runs the crawler to discover media, then downloads media, extracts frames for videos, runs OCR on images/frames, and writes processed results.

---

## Example end-to-end run (download + frames + OCR)

1. Ensure `config.yaml` is properly configured.
2. Run:
   ```bash
   ruby bin/run.rb config.yaml
   ```
   Or:
   ```bash
   ruby bin/run.rb https://example.com 2
   ```

After the run completes:
- Initial discovered resources are saved to `output/results.json`.
- Downloaded media and OCR outputs are saved and a final processed results file is written to `output/processed_results.json`.

---

## Output layout

By default `output/` (or your configured `output_dir`) contains:

- `output/images/` — downloaded images
- `output/videos/` — downloaded video files
- `output/video_frames/` — extracted frames for videos (organized per-video)
- `output/results.json` — JSON file of discovered resources (pre-processing)
- `output/processed_results.json` — JSON file including download paths and OCR text

`results.json` entries follow the format produced by `ResultRecorder.build`:
```json
{
  "source_page": "https://example.com",
  "type": "image",
  "url": "https://example.com/assets/img.jpg",
  "path": null,
  "text": null
}
```
After processing, `processed_results.json` will have `path` filled with local file paths and `text` with OCR output.

---

## Testing & Linting

- Run tests (RSpec):
  ```bash
  bundle exec rspec
  # or via rake
  rake spec
  ```

- Lint with RuboCop:
  ```bash
  bundle exec rubocop
  # or via rake
  rake lint
  ```

---

## Troubleshooting

- "tesseract: command not found" — install Tesseract and ensure PATH updated.
- "ffmpeg: command not found" — install FFmpeg and ensure PATH updated.
- Downloads failing — adjust `user_agent` in `config.yaml`.
- If `output/` is missing — verify write permissions and `config.yaml` `output_dir`.

---

## Extending

- Add selectors in `config.yaml` to target other tags or attributes.
- Extend managers to perform additional processing, filtering, or remote storage.
- Swap/override `MemoryManager` for a different GC strategy by dependency-injecting into `Crawler`.

---

## Development notes

- Core files:
  - `lib/ocr_crawler/config.rb` — YAML config loader
  - `lib/ocr_crawler/crawler.rb` — main orchestration
  - `lib/ocr_crawler/link_manager.rb` — link extraction
  - `lib/ocr_crawler/image_manager.rb` & `video_manager.rb` — selector-driven extraction
  - `lib/ocr_crawler/downloader.rb` — HTTP resource downloader
  - `lib/ocr_crawler/ffmpeg_helper.rb` — frame extraction helper (calls FFmpeg)
  - `lib/ocr_crawler/ocr_executor.rb` — RTesseract wrapper
  - `lib/ocr_crawler/result_recorder.rb` — save JSON results

All modules/classes include short docstring comments.

---

## License

MIT — see LICENSE file.
