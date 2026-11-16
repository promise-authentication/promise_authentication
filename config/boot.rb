ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Coverage must start before the app loads; see test/start_coverage.rb.
require_relative "../test/start_coverage" if File.basename($PROGRAM_NAME) == "rails" && ARGV.first == "test"
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
