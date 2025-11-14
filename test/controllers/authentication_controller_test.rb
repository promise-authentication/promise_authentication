require 'test_helper'

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test 'the login screen' do
    get login_url
    assert_response :success

    assert_select 'input#email'
  end

  test 'the login screen with relying party' do
    get login_url, params: { relying_party_id: 'example.com' }
    assert_response :success

    assert_select 'input#email'
    assert_select 'h2', 'Sign in'
  end

  test 'authenticating with nothing' do
    post authenticate_url
    assert_response :redirect
  end

  test 'authentication with non existing email' do
    post authenticate_url,
         params: { email: 'hello@world.com', password: 'secret', remember_me: 1 }
    assert_redirected_to login_url(email: 'hello@world.com', remember_me: '1')
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal nil, jar.encrypted[:user_id]
  end

  test 'authentication with no relying party' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!

    post authenticate_url,
         params: { email: 'hello@world.com', password: 'secret', remember_me: 1 }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
    email = jar.encrypted[:email]

    assert_equal 'hello@world.com', email
    assert Authentication::Vault.personal_data(user_id, vault_key)
  end

  test 'logout' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!

    post authenticate_url, params: { email: 'hello@world.com', password: 'secret', remember_me: 1 }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert jar.encrypted[:user_id]

    delete logout_url

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:user_id]
    assert_nil jar.encrypted[:vault_key_base64]
    assert_nil jar.encrypted[:email]
  end

  test 'authentication with relying party' do
    Trust::Certificate.generate_key_pair!

    Authentication::RelyingParty.stub :fetch, nil do
      Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
      post authenticate_url,
           params: { email: 'hello@world.com', password: 'secret',
                     client_id: 'party.com', remember_me: 1 }
    end

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
    email = jar.encrypted[:email]

    assert_equal 'hello@world.com', email
    assert Authentication::Vault.personal_data(user_id, vault_key)
  end

  test 'showing email after login' do
    Trust::Certificate.generate_key_pair!

    Authentication::RelyingParty.stub :fetch, nil do
      Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!

      post authenticate_url, params: {
        email: 'hello@world.com',
        password: 'secret',
        client_id: 'party.com',
        remember_me: 1
      }
      # It will redirect to the relying party
      assert_redirected_to %r(\Ahttps://party.com/authenticate)

      get confirm_path(client_id: 'party.com')
      assert_response :success

      assert_select 'p', /hello@world\.com/
    end
  end

  test 'relying party with legacy accounts and no existing account' do
    email = 'hello@world.com'
    password = 'secr2t'
    relying_party_id = 'example.com'

    relying_party = Minitest::Mock.new
    relying_party.expect :locale, nil
    relying_party.expect :id, relying_party_id
    relying_party.expect :id, relying_party_id
    relying_party.expect :knows_legacy_account?, true, [email]
    relying_party.expect :knows_legacy_account?, true, [email]
    relying_party.expect :legacy_account_user_id_for, 'leguid', [email, password]
    relying_party.expect :legacy_account_user_id_for, 'leguid', [email, password]
    relying_party.expect :present?, true
    relying_party.expect :id, relying_party_id
    relying_party.expect :redirect_uri, 'https://example.com/hello' do |kwargs|
      kwargs[:id_token].is_a?(Authentication::IdToken) && 
      kwargs[:login_configuration].is_a?(ActionController::Parameters)
    end

    Authentication::RelyingParty.stub :find, relying_party do
      Authentication::Services::Authenticate.new(email: email, password: password).register!

      post authenticate_url,
           params: { email: email, password: password, client_id: relying_party_id,
                     remember_me: 1 }

      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      user_id = jar.encrypted[:user_id]
      vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
      personal_data = Authentication::Vault.personal_data(user_id, vault_key)
      assert_equal personal_data.id_for(relying_party_id), 'leguid'

      # It will record that the password is known by relying party
      event = Rails.configuration.event_store.read.of_type(Authentication::Events::PasswordSet).last
      assert_equal event.data[:password_known_by_relying_party_id], relying_party_id

      assert_mock relying_party

      assert_redirected_to 'https://example.com/hello'
    end
  end

  test 'relying party with legacy accounts and an existing account' do
    Trust::Certificate.generate_key_pair!

    email = 'hello@world.com'
    password = 'secr2t'
    relying_party_id = 'example.com'

    # Create existing account
    Authentication::Services::Authenticate.new(email: email, password: password).register!
    post authenticate_url, params: { email: email, password: password }

    relying_party = Minitest::Mock.new
    relying_party.expect :locale, nil
    relying_party.expect :id, relying_party_id
    relying_party.expect :present?, true
    relying_party.expect :id, relying_party_id
    relying_party.expect :redirect_uri, 'https://example.com/hello' do |kwargs|
      kwargs[:id_token].is_a?(Authentication::IdToken) && 
      kwargs[:login_configuration].is_a?(ActionController::Parameters)
    end

    Authentication::RelyingParty.stub :find, relying_party do
      post authenticate_url, params: { email: email, password: password, client_id: relying_party_id, remember_me: 1 }

      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      user_id = jar.encrypted[:user_id]
      vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
      personal_data = Authentication::Vault.personal_data(user_id, vault_key)
      assert personal_data.id_for(relying_party_id)

      # It will record that the password is knowns by relying party
      event = Rails.configuration.event_store.read.of_type(Authentication::Events::PasswordSet).last
      assert_nil event.data[:password_known_by_relying_party_id]

      assert_mock relying_party

      assert_redirected_to 'https://example.com/hello'
    end
  end

  test 'go_to relying party' do
    Trust::Certificate.generate_key_pair!

    email = 'hello@world.com'
    password = 'secr2t'
    relying_party_id = 'example.com'
    Authentication::Services::Authenticate.new(email: email, password: password).register!

    post authenticate_url, params: { email: email, password: password }
    assert_response :redirect

    Authentication::RelyingParty.stub :fetch, nil do
      post go_to_url, params: { client_id: relying_party_id, nonce: 'abc', redirect_uri: 'https://example.com/hello' }
    end

    assert_response :redirect
    uri = URI.parse(response.redirect_url)

    assert_equal uri.host, 'example.com'
    assert_equal uri.path, '/hello'
    query = URI.decode_www_form(uri.query || '')
    assert_equal query[0][0], 'id_token'

    id_token = query[0][1]
    _payload, header = JWT.decode(id_token, nil, false)
    key = Trust::Certificate.current.public_key
    decoded_token = JWT.decode(id_token, key, true, { algorithm: header['alg'] }).first

    assert decoded_token['sub']
    assert decoded_token['iat']
    assert_equal decoded_token['nonce'], 'abc'
    assert_equal decoded_token['iss'], 'https://promiseauthentication.org'
    assert_equal decoded_token['aud'], 'example.com'

    # It will create an event

    stats = Statistics::SignInEvent.last
    assert_equal stats.user_id, decoded_token['sub']
    assert_equal stats.relying_party_id, decoded_token['aud']
    assert_equal stats.token_id, decoded_token['jti']
  end
end
