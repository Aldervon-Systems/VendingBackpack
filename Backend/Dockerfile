# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.10
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Default environment; can be overridden in docker-compose.
ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="0" \
    BUNDLE_PATH="/usr/local/bundle"


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config libyaml-dev

# Install application gems
COPY Gemfile Gemfile.lock ./
ARG BUNDLER_VERSION=4.0.3
RUN gem install bundler -v "$BUNDLER_VERSION"
# Force cache break
ARG CACHE_DATE=2026-01-31T0515
RUN echo $CACHE_DATE && bundle lock --add-platform x86_64-linux && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Ensure lockfile is updated for development platform if it was overwritten
RUN bundle lock --add-platform x86_64-linux

# Ensure scripts use Unix line endings
RUN find ./bin -type f -print0 | xargs -0 sed -i 's/\r$//' || true

# Precompile bootsnap code
RUN bundle exec bootsnap precompile app/ lib/


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp data
USER rails:rails

# Entrypoint prepares the database (not used in fixture-backed mode), but keep as default.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 9090
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "9090"]
