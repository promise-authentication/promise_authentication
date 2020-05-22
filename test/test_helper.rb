ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  setup do
    @old_domain = ENV['PROMISE_KEY_REGISTRY_API_ROOT']
    ENV['PROMISE_KEY_REGISTRY_API_ROOT'] = "https://somewhere.nice"
    key_site = ENV['PROMISE_KEY_REGISTRY_API_ROOT']
    key = RbNaCl::PrivateKey.generate
    stub_request(:post, "#{key_site}/key_pairs.json").
    with(
      body: "{}",
      headers: {
     'Accept'=>'*/*',
     'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
     'Content-Type'=>'application/json',
     'User-Agent'=>'Ruby'
      }).
      to_return(status: 200, body: "{\"public_key\":\"#{Base64.strict_encode64(key.public_key)}\"}", headers: {})


      stub_request(:get, "#{key_site}/key_pairs/#{CGI.escape Base64.strict_encode64(key.public_key)}.json").
      with(
        headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby'
        }).
        to_return(status: 200, body: "{\"private_key\": \"#{Base64.strict_encode64(key)}\"}", headers: {})


      stub_request(:get, "https://example.com/.well-known/promise.json").
        with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Faraday v1.0.1'
          }).
          to_return(status: 200, body: "", headers: {})
  end

  teardown do
    ENV['PROMISE_KEY_REGISTRY_API_ROOT'] = @old_domain
  end
end
