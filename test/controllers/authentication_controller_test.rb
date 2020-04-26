require 'test_helper'

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test 'the login screen' do
    get login_url
    assert_response :success

    assert_select 'input#email'
    assert_select 'input#password'
  end

  test 'the login screen with relying party' do
    get login_url, params: { relying_party_id: 'example.com' }
    assert_response :success

    assert_select 'input#email'
    assert_select 'input#password'
    assert_select 'h2', 'Login'
  end

  test 'authenticating with nothing' do
    post authenticate_url
    assert_response :redirect
  end

  test 'authentication with no relying party' do
    post authenticate_url, params: { email: 'hello@world.com', password: 'secret' }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    vault_key = jar.encrypted[:vault_key]
    email = jar.encrypted[:email]

    assert_equal 'hello@world.com', email
    assert Authentication::Vault.personal_data(user_id, vault_key)
  end

  test 'logout' do
    post authenticate_url, params: { email: 'hello@world.com', password: 'secret' }
    get logout_url

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:user_id]
    assert_nil jar.encrypted[:vault_key]
    assert_nil jar.encrypted[:email]
  end

  test 'authentication with relying party' do
    post authenticate_url, params: { email: 'hello@world.com', password: 'secret', aud: 'party.com' }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    vault_key = jar.encrypted[:vault_key]
    email = jar.encrypted[:email]

    assert_equal 'hello@world.com', email
    assert Authentication::Vault.personal_data(user_id, vault_key)
  end

  test 'showing email after login' do
    post authenticate_url, params: { email: 'hello@world.com', password: 'secret', aud: 'party.com' }
    assert_redirected_to confirm_path(aud: 'party.com')

    get confirm_path(aud: 'party.com')
    assert_response :success

    assert_select 'p', /hello@world\.com/
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
    relying_party.expect :legacy_account_user_id_for, 'leguid', [email, password]

    Authentication::RelyingParty.stub :find, relying_party do
      post authenticate_url, params: { email: email, password: password, aud: relying_party_id }

      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      user_id = jar.encrypted[:user_id]
      vault_key = jar.encrypted[:vault_key]
      personal_data = Authentication::Vault.personal_data(user_id, vault_key)
      assert_equal personal_data.id_for(relying_party_id), 'leguid'

      # It will record that the password is knowns by relying party
      event = Rails.configuration.event_store.read.of_type(Authentication::Events::PasswordSet).last
      assert_equal event.data[:password_known_by_relying_party_id], relying_party_id

      assert_mock relying_party

      assert_redirected_to confirm_path(aud: relying_party_id)
    end
  end

  test 'relying party with legacy accounts and an existing account' do
    email = 'hello@world.com'
    password = 'secr2t'
    relying_party_id = 'example.com'

    # Create existing account
    post authenticate_url, params: { email: email, password: password }

    relying_party = Minitest::Mock.new
    relying_party.expect :locale, nil
    relying_party.expect :id, relying_party_id

    Authentication::RelyingParty.stub :find, relying_party do
      post authenticate_url, params: { email: email, password: password, aud: relying_party_id }

      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      user_id = jar.encrypted[:user_id]
      vault_key = jar.encrypted[:vault_key]
      personal_data = Authentication::Vault.personal_data(user_id, vault_key)
      assert_nil personal_data.id_for(relying_party_id)

      # It will record that the password is knowns by relying party
      event = Rails.configuration.event_store.read.of_type(Authentication::Events::PasswordSet).last
      assert_nil event.data[:password_known_by_relying_party_id]

      assert_mock relying_party

      assert_redirected_to confirm_path(aud: relying_party_id)
    end
  end
end
