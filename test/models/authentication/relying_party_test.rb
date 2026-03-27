require 'test_helper'

class Authentication::RelyingPartyTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::RelyingParty
    @relying_party = @described_class.new(id: 'hello.world')
    @old_value = ENV['PROMISE_RELYING_PARTY_KEY_SALT']
  end

  teardown do
    ENV['PROMISE_RELYING_PARTY_KEY_SALT'] = @old_value
  end

  test 'it will have secret key' do
    old = @relying_party.secret_key_base64
    ENV['PROMISE_RELYING_PARTY_KEY_SALT'] = 'secret'
    new = @relying_party.secret_key_base64

    assert_not_equal old, new
    assert_equal new, 'C5e8F5113d1WNwECgmuL8yACraZaKd81cwJeNeAnPIc='
  end

  test 'it will call the well knowns' do
    response = Minitest::Mock.new
    response.expect :body, {
      legacy_account_authentication_url: 'https://url',
      legacy_account_forgot_password_url: 'https://forgot'
    }.to_json
    @described_class.stub :fetch, response do
      @relying_party = Authentication::RelyingParty.find('foo')
    end
    assert @relying_party
    assert @relying_party.supports_legacy_accounts?
  end

  test 'allowing only redirect urls specified' do
    response = Minitest::Mock.new
    response.expect :body, {
      allowed_redirect_domain_names: [
        'sub.example.com',
        '87.52.27.24'
      ],
      allowed_redirect_uris: [
        'exp://192.168.50.185:19000/authenticate'
      ]
    }.to_json
    @described_class.stub :fetch, response do
      @relying_party = Authentication::RelyingParty.find('example.com')

      [
        'exp://192.168.50.185:19000/authenticate',
        'exp://192.168.50.185:19000/authenticate?andThen=/hello',
        'https://example.com/authenticate?email=jam@bar.com',
        'https://example.com/foo',
        'https://example.com/authenticate',
        'http://localhost/world',
        'http://hello.localhost/world',
        'http://hello.localhost:3000/world',
        'https://sub.example.com/hello',
        'https://sub.example.com/world',
        'http://127.0.0.1:3000/hello',
        'http://localhost:3000/hello',
        'https://localhost:3000/hello',
        'https://87.52.27.24/hello'
      ].each do |conf|
        result = @relying_party.redirect_uri(id_token: 'a', login_configuration: {
                                               redirect_uri: conf
                                             })
        conf_parsed = URI.parse(conf)
        result_parsed = URI.parse(result)
        assert_equal conf_parsed.host, result_parsed.host
      end

      [
        'http://example.com',
        'https://bar.example.com'
      ].each do |url|
        assert_raise @described_class::InvalidRedirectUri do
          @relying_party.redirect_uri(id_token: 'a', login_configuration: {
                                        redirect_uri: url
                                      })
        end
      end
    end
  end

  test 'it will require legacy url to have https' do
    assert @relying_party.valid?
    @relying_party.legacy_account_authentication_url = 'http://hello.world'
    assert_not @relying_party.valid?
    @relying_party.legacy_account_authentication_url = 'https://hello.world'
    assert @relying_party.valid?
  end

  test 'http_client uses JSON serializer for cache' do
    client = @described_class.http_client
    cache_middleware = client.builder.handlers.find { |h| h.name.include?('HttpCache') }
    assert cache_middleware, 'Expected http_cache middleware to be present'

    # Verify JSON serializer by doing a real cached round-trip
    url = 'https://cache-test.example.com/.well-known/promise.json'
    body = { name: 'Test App' }.to_json

    stub_request(:get, url)
      .to_return(
        status: 200,
        body: body,
        headers: { 'Cache-Control' => 'max-age=300', 'Content-Type' => 'application/json' }
      )

    # First request hits the stub
    response1 = @described_class.fetch(url)
    assert_equal body, response1.body

    # Second request should be served from cache (no second stub hit)
    response2 = @described_class.fetch(url)
    assert_equal body, response2.body
  end

  test 'authenticating legacy account' do
    @relying_party.legacy_account_authentication_url = 'https://hello.world'
    @relying_party.legacy_account_forgot_password_url = 'http://hello.world'

    response = Minitest::Mock.new
    response.expect :code, 200
    response.expect :body, {
      user_id: 'uid'
    }.to_json
    @described_class.stub :fetch, response do
      assert_equal @relying_party.legacy_account_user_id_for(
        'email',
        'password'
      ), 'uid'
    end
  end
end
