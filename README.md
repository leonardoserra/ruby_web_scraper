# Ruby OCR Crawler

A modular, memory-safe Ruby web crawler that downloads images and videos and performs OCR (Tesseract) on them.

## Requirements
- Ruby >= 3.1
- Tesseract installed on system: `sudo apt install tesseract-ocr` or Windows via winget
- FFmpeg for video frame extraction: `sudo apt install ffmpeg` or Windows via winget

## Setup
1. Install gems:
   ```bash
   bundle install
   ```
2. Run the crawler:
   ```bash
    rake 'run[https://example.com,2]'
   ```
3. Results will be in the `output/` directory.
