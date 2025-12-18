# ---- Base image ----
FROM ruby:3.4.8-trixie

# ---- Environment variables ----
ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLE_PATH="/usr/local/bundle"

# ---- Install system dependencies ----
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tesseract-ocr \
    tesseract-ocr-eng \
    curl \
    gem install bundler -v 2.7.2 \
    && rm -rf /var/lib/apt/lists/*

# ---- Set working directory ----
WORKDIR /app

# ---- Install Ruby dependencies ----
COPY Gemfile Gemfile.lock ./
RUN bundle install

# ---- Copy project ----
COPY . .

# ---- Default command ----
CMD ["rake", "run[https://example.com,2]"]
