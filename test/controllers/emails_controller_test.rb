require 'test_helper'

class EmailsControllerTest < ActionDispatch::IntegrationTest
  test 'changing email' do
    @email = 'hello@example.com'
    @new_email = 'hello@world.com'
    @old_password = 'old'
    Authentication::Services::Authenticate.new(email: @email, password: @old_password).register!
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]

    post '/email', params: { new_email: @new_email }

    # I can not use the new email to authenticate
    post '/authenticate', params: { email: @new_email, password: @old_password, remember_me: 1 }
    assert_response :unauthorized

    # I can still use the old email to authenticate
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]

    # When get the confirmation code from the email, I can use the new email
    code = EmailVerificationCode.find_by_cleartext(@new_email)
    post '/email', params: { new_email: @new_email, confirmation_code: code.code }
    assert_response :success

    post '/authenticate', params: { email: @new_email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]

    # Can still read personal data
    vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
    user_id = jar.encrypted[:user_id]
    personal_data = Authentication::Vault.personal_data(user_id, vault_key)
    assert personal_data
  end
end
