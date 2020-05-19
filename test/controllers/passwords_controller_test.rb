require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test 'changing password' do
    @email = 'hello@example.com'
    @old_password = 'old'
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    assert cookies[:user_id]
    assert cookies[:vault_key_base64]

    post '/password', params: { current_password: @old_password, new_password: 'new' }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)

    # Can still read personal data
    vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
    user_id = jar.encrypted[:user_id]
    personal_data = Authentication::Vault.personal_data(user_id, vault_key)
    assert personal_data
  end

  test 'recovering password when mail not present' do
    assert_emails 1 do
      post '/password/recover', params: { email: 'not@there.com' }
      email = ActionMailer::Base.deliveries.first
      assert_includes email.html_part.body.to_s, 'not@there.com'
    end
    assert_redirected_to wait_password_path
  end

  test 'recovering password when mail present' do
    @email = 'hello@example.com'
    @old_password = 'old'
    auth = Authentication::Services::Authenticate.new(
      email: @email,
      password: @old_password
    )
    auth.call!

    assert_emails 1 do
      post '/password/recover', params: { email: @email }
      token = Authentication::RecoveryToken.where(user_id: auth.user_id).last.token
      email = ActionMailer::Base.deliveries.first
      assert_includes email.to, @email
      assert_includes email.html_part.body.to_s, token
      assert_includes email.text_part.body.to_s, token
    end
    assert_redirected_to wait_password_path
  end
end

