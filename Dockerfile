# Use Ruby 3.0.2 as base image
FROM ruby:3.0.2-slim

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libsqlite3-dev \
    nodejs \
    git \
    postgresql \
    postgresql-client \
    libpq-dev \
    libsodium-dev \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g yarn

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install dependencies
RUN bundle install

# Copy the rest of the application
COPY . .

# Set environment to development
ENV RAILS_ENV=development
ENV RAILS_SERVE_STATIC_FILES=true

# Install yarn packages
RUN yarn install

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
