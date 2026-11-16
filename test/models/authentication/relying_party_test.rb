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
    response.expect :status, 200
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
    response.expect :status, 200
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

  test 'well knowns falls back to the last good copy when the fetch fails' do
    Rails.stub :cache, ActiveSupport::Cache::MemoryStore.new do
      response = Minitest::Mock.new
      response.expect :status, 200
      response.expect :body, { allowed_redirect_uris: ['app://authenticate'] }.to_json
      @described_class.stub :fetch, response do
        @described_class.find('example.com')
      end

      # The party's site goes down — the cached whitelist keeps logins working.
      @described_class.stub :fetch, nil do
        relying_party = @described_class.find('example.com')
        result = relying_party.redirect_uri(id_token: 'a', login_configuration: {
                                              redirect_uri: 'app://authenticate'
                                            })
        assert_match %r{\Aapp://authenticate\?id_token=}, result
      end
    end
  end

  test 'an unreachable party without a cached copy raises WellKnownUnavailable' do
    @described_class.stub :fetch, nil do
      relying_party = @described_class.find('example.com')

      # This uri might be whitelisted — we just can't know right now.
      assert_raise @described_class::WellKnownUnavailable do
        relying_party.redirect_uri(id_token: 'a', login_configuration: {
                                     redirect_uri: 'app://authenticate'
                                   })
      end

      # Host-based validation needs no well-known and still works.
      result = relying_party.redirect_uri(id_token: 'a', login_configuration: {
                                            redirect_uri: 'https://example.com/cb'
                                          })
      assert_match %r{\Ahttps://example.com/cb\?id_token=}, result
    end
  end

  test 'a party whose well-known 5xxes after all retries degrades instead of crashing' do
    final = Struct.new(:status, :body).new(503, 'Service Unavailable')
    client = Object.new
    client.define_singleton_method(:get) { |_url| raise Faraday::RetriableResponse.new(nil, final) }

    @described_class.stub :http_client, client do
      assert_equal final, @described_class.fetch('https://party.dead/promise.json')

      relying_party = @described_class.find('party.dead')
      assert relying_party.well_known_unavailable
    end
  end

  test 'it will require legacy url to have https' do
    assert @relying_party.valid?
    @relying_party.legacy_account_authentication_url = 'http://hello.world'
    assert_not @relying_party.valid?
    @relying_party.legacy_account_authentication_url = 'https://hello.world'
    assert @relying_party.valid?
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

  test 'a well-known that is not JSON counts as an empty config' do
    stub_request(:get, 'https://garbled.example/.well-known/promise.json')
      .to_return(status: 200, body: '<html>not json</html>')

    relying_party = @described_class.find('garbled.example')

    assert_equal 'garbled.example', relying_party.id
    assert_nil relying_party.well_known_unavailable
  end

  test 'fetch goes over the real http client and follows redirects' do
    stub_request(:get, 'https://moved.example/.well-known/promise.json')
      .to_return(status: 301, headers: { 'Location' => 'https://new.example/promise.json' })
    stub_request(:get, 'https://new.example/promise.json')
      .to_return(status: 200, body: { name: 'Moved' }.to_json)

    assert_equal 'Moved', @described_class.find('moved.example').name
  end

  test 'fetch and head give nil when the party cannot be reached' do
    stub_request(:any, 'https://down.example/logo.png').to_timeout

    assert_nil @described_class.fetch('https://down.example/logo.png')
    assert_nil @described_class.head('https://down.example/logo.png')
  end

  test 'head hands back the final response when it keeps 5xxing' do
    final = Struct.new(:status).new(503)
    client = Object.new
    client.define_singleton_method(:head) { |_url| raise Faraday::RetriableResponse.new(nil, final) }

    @described_class.stub :http_client, client do
      assert_equal final, @described_class.head('https://party.dead/logo.png')
    end
  end

  test 'logo data is inlined when the logo is a small image' do
    png = 'PNGDATA'
    headers = { 'Content-Type' => 'image/png', 'Content-Length' => png.bytesize.to_s }
    stub_request(:head, 'https://hello.world/logo.png').to_return(status: 200, headers: headers)
    stub_request(:get, 'https://hello.world/logo.png').to_return(status: 200, body: png, headers: headers)
    @relying_party.logo_url = 'https://hello.world/logo.png'

    assert_equal "data:image/png;base64,#{Base64.strict_encode64(png)}", @relying_party.logo_data
  end

  test 'logo data is nil without a logo url' do
    assert_nil @relying_party.logo_data
  end

  test 'logo data is nil for empty, huge or non-image logos' do
    @relying_party.logo_url = 'https://hello.world/logo.png'

    [
      { 'Content-Type' => 'image/png', 'Content-Length' => '0' },
      { 'Content-Type' => 'image/png', 'Content-Length' => 1_048_576.to_s },
      { 'Content-Type' => 'text/html', 'Content-Length' => '10' }
    ].each do |headers|
      stub_request(:head, 'https://hello.world/logo.png').to_return(status: 200, headers: headers)
      assert_nil @relying_party.logo_data, headers.inspect
    end
  end

  test 'logo data is nil when the download does not match the head request' do
    @relying_party.logo_url = 'https://hello.world/logo.png'
    head = { 'Content-Type' => 'image/png', 'Content-Length' => '7' }
    stub_request(:head, 'https://hello.world/logo.png').to_return(status: 200, headers: head)

    [
      { status: 404, body: 'PNGDATA', headers: head },
      { status: 200, body: 'PNGDATA', headers: head.merge('Content-Type' => 'image/gif') },
      { status: 200, body: 'PNGDATA', headers: head.merge('Content-Length' => '8') },
      { status: 200, body: 'PNG', headers: head }
    ].each do |response|
      stub_request(:get, 'https://hello.world/logo.png').to_return(response)
      assert_nil @relying_party.logo_data, response.inspect
    end
  end

  test 'name html keeps the name on one line' do
    @relying_party.name = 'Hello World'
    assert_equal 'Hello&nbspWorld', @relying_party.name_html
    assert @relying_party.name_html.html_safe?
  end
end
