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
    libgtk-3-0 \
    libgdk-pixbuf-xlib-2.0-0 \
    libpango-1.0-0 \
    tor \
    privoxy \
    netcat-openbsd \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.7.2

# ---- Set working directory ----
WORKDIR /app

# ---- Install Ruby dependencies ----
COPY Gemfile Gemfile.lock ./
RUN bundle install

# ---- Copy project ----
COPY . .

# ---- Entrypoint: starts Tor + Privoxy, then runs CMD ----
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# ---- Default command ----
CMD ["rake", "run[https://example.com,2]"]
