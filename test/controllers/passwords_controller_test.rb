require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @email = 'hello@example.com'
    @old_password = 'old'
    post '/authenticate', params: { email: @email, password: @old_password }
    assert cookies[:user_id]
    assert cookies[:vault_key]
  end

  test 'changing password' do
    post '/password', params: { current_password: @old_password, new_password: 'new' }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)

    # Can still read personal data
    vault_key = jar.encrypted[:vault_key]
    user_id = jar.encrypted[:user_id]
    personal_data = Authentication::Vault.personal_data(user_id, vault_key)
    assert_equal @email, personal_data.emails.first
  end
end

