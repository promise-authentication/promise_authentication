# Not named coverage.rb: with -Itest it would shadow Ruby's own `require 'coverage'`.
# Starts coverage. Required from config/boot.rb for `bin/rails test`, which
# boots the app in test:prepare (tailwindcss:build depends on :environment)
# before test_helper is loaded, and from test_helper for other runners.
# `require` loads this file once, so whichever comes first starts it.
require 'bundler/setup' # already done when coming from config/boot.rb
require 'simplecov'

SimpleCov.start 'rails' do
  enable_coverage :branch
  skip %r{^/(config|db|test|vendor)/}
  # Enforced in CI only, so running a single test file locally doesn't fail.
  minimum_coverage line: 100 if ENV['CI']

  # Rails forks the test workers after the app has booted. SimpleCov's own
  # subprocess support restarts Coverage in each fork, which drops every file
  # loaded before the fork (initializers, to_prepare). Keep the inherited
  # counters instead; test_helper names each worker's result.
  merge_subprocesses false
end
