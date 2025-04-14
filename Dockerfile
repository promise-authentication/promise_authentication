# Use Ruby 3.2.8 as base image
FROM ruby:3.2.8-slim

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libsqlite3-dev \
    git \
    vim \
    postgresql \
    postgresql-client \
    libpq-dev \
    libsodium-dev \
    curl \
    gnupg2 \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g yarn

# Set working directory
WORKDIR /app

# Install bundler and configure it
RUN gem install bundler:2.5.23 \
    && bundle config set --local without 'production'

# Copy Gemfile and Gemfile.lock
COPY Gemfile ./

# Install dependencies
RUN bundle install

# Copy package.json and yarn.lock if they exist
COPY package.json yarn.lock ./

# Install yarn packages if package.json exists
RUN if [ -f package.json ]; then yarn install; fi

# Copy the rest of the application
COPY . .

# Set environment to development
ENV RAILS_ENV=development
ENV RAILS_SERVE_STATIC_FILES=true

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
