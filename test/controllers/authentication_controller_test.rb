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
    service = Minitest::Mock.new
    service.expect :valid?, true
    service.expect :user_id_and_vault_key, ['uid', 'key']
    Authentication::Vault.stub :key_from, 'key' do
      Authentication::Services::Authenticate.stub :new, service do
        post authenticate_url, params: { email: 'hello@world.com', password: 'secret' }

        assert_mock service
        jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
        assert_equal jar.encrypted[:user_id], 'uid'
        assert_equal jar.encrypted[:vault_key], 'key'
      end
    end
  end

  test 'authentication with relying party' do
    auth_service = Minitest::Mock.new
    auth_service.expect :valid?, true
    auth_service.expect :user_id_and_vault_key, ['uid', 'key']

    Authentication::Vault.stub :key_from, 'key' do
      Authentication::Services::Authenticate.stub :new, auth_service do
          post authenticate_url, params: { email: 'hello@world.com', password: 'secret', aud: 'party.com' }

          assert_mock auth_service

          jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
          assert_equal jar.encrypted[:user_id], 'uid'
          assert_equal jar.encrypted[:vault_key], 'key'

          assert_redirected_to confirm_path(aud: 'party.com')
      end
    end
  end
end
