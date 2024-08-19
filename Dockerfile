# Set the alpine version so they match for both images
ARG ALPINE_VERSION=3.19

# Set the NodeJS version
ARG NODE_VERSION=iron

# Set the Ruby version
ARG RUBY_VERSION=3.3.3

# Pull in the NodeJS image
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS node

# Pull in the Ruby image
FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION} AS base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

# Set environment args from build args
ARG GIT_COMMIT
ENV GIT_COMMIT=$GIT_COMMIT

ARG APP_RUN_SIDEKIQ
ENV APP_RUN_SIDEKIQ=$APP_RUN_SIDEKIQ

ARG APP_RUN_RAKE_TASKS
ENV APP_RUN_RAKE_TASKS=$APP_RUN_RAKE_TASKS

ARG CLAMAV_SERVER_IP
ENV CLAMAV_SERVER_IP=$CLAMAV_SERVER_IP

ARG ASSETS_BUCKET
ENV ASSETS_BUCKET=$ASSETS_BUCKET

ARG APP_RUN_PRECOMPILE_ASSETS
ENV APP_RUN_PRECOMPILE_ASSETS=$APP_RUN_PRECOMPILE_ASSETS

# Collects the environment variables from the parameter store
##_PARAMETER_STORE_MARKER_##

# Throw-away build stage to reduce size of final image
FROM base AS build

# As this is a multistage Docker image build
# we will pull in the contents from the previous node image build stage
# to our current ruby build image stage
# so that the ruby image build stage has the correct nodejs version
COPY --from=node /usr/local/bin /usr/local/bin

# Install application dependencies
RUN apk add --update --no-cache \
    build-base \
    curl \
    git \
    libpq-dev \
    npm \
    tzdata

# Enable corepack for yarn
RUN corepack enable

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
RUN yarn workspaces focus --all --production

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN GOOGLE_GEOCODING_API_KEY=dummy SECRET_KEY_BASE_DUMMY=1 APP_RUN_PRECOMPILE_ASSETS="FALSE" ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apk add --update --no-cache \
    bash \
    ca-certificates \
    clamav \
    clamav-daemon \
    curl \
    libpq-dev \
    nginx \
    tzdata

# Setup nginx for Sidekiq
RUN mkdir -p /run/nginx
COPY default.conf /etc/nginx/http.d/default.conf

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN adduser rails -D --shell /bin/bash

# Own the runtime files for the app
RUN chown -R rails:rails db log storage tmp data

# Own the runtime files for ClamAV
RUN chown -R rails:rails /etc/clamav/clamd.conf

# Own the runtime files for nginx
RUN chown -R rails:rails /var/lib/nginx /var/log/nginx /var/run/nginx

USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Run the web app on port 8080
ENV PORT=8080
EXPOSE 8080

# Start the server by default, this can be overwritten at runtime
CMD ["./bin/rails", "server"]
