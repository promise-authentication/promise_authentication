require 'test_helper'

class HumansControllerTest < ActionDispatch::IntegrationTest
  test 'the login screen' do
    get login_url
    assert_response :success

    assert_select 'input#email'
    assert_select 'input#password'
  end

  test 'authenticating with nothing' do
    post authenticate_url
    assert_response :redirect
  end

  test 'authentication with something' do
    service = Minitest::Mock.new
    service.expect :valid?, true
    service.expect :user_id_and_salt, ['uid', 'salt']
    service.expect :password, 'secret'
    Authentication::Vault.stub :key_from, 'key' do
      Authentication::Services::Authenticate.stub :new, service do
        post authenticate_url, params: { email: 'hello@world.com', password: 'secret' }

        assert_mock service
        assert_equal session[:user_id], 'uid'
        assert_equal session[:vault_key], 'key'
      end
    end
  end
end
