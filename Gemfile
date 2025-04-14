source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.8'

# Event store
gem "rails_event_store", "1.3.0"
# Cryptography
gem 'rbnacl', "7.1.1"

gem 'retries'

gem 'jwt'

gem 'faraday-http-cache'
gem 'faraday_middleware'

gem 'color-generator'

gem 'airbrake'

# For background processing powered by RabbitMQ
gem 'sneakers', "2.12.0"

# To be able to .to_jwk on key
gem 'json-jwt'

# For analytics
gem 'ahoy_matey', '~> 3.2.0'
gem 'chartkick'
gem 'groupdate'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8'
# Use Puma as the app server
gem 'puma' #, '~> 5.2'
# Use SCSS for stylesheets
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker', '~> 5.2'
gem 'jsbundling-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks' #, '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap' #, '>= 1.4.2', require: false

gem 'sprockets-rails'

gem 'redcarpet'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :production do
  gem 'pg'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console' #, '>= 3.3.0'
  gem 'listen' # , '>= 3.0.5', '< 3.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Use sqlite3 as the database for Active Record
  gem 'sqlite3' #, '~> 1.4'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "activeresource" #, "~> 5.1"

gem "webmock", "~> 3.12"

# gem "matrix", "~> 0.4.2"

gem "tailwindcss-rails", "2.0.25"
