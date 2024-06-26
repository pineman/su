FROM ruby:3.3.3-slim-bookworm as base
ENV BUNDLE_APP_CONFIG=/usr/local/bundle \
    GEM_HOME=/usr/local/bundle \
    BUNDLE_SILENCE_ROOT_WARNING=1


# Rack app lives here
WORKDIR /app

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential

# Install application gems
COPY Gemfile* .
RUN bundle install


# Final stage for app image
FROM base

# Run and own the application files as a non-root user for security
RUN useradd ruby --home /app --shell /bin/bash
USER ruby:ruby

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=ruby:ruby /app /app

# Copy application code
COPY --chown=ruby:ruby . .

# Start the server
EXPOSE 8080
ENV RUBYOPT="--yjit"
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "8080"]
