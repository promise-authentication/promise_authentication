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
    assert_equal @email, jar.encrypted[:email]

    # I can not use the new email to authenticate
    post '/authenticate', params: { email: @new_email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:user_id]

    # I can still use the old email to authenticate
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal @email, jar.encrypted[:email]

    post '/email', params: { email: @new_email }
    assert_response :redirect

    # I can not use the new email to authenticate
    post '/authenticate', params: { email: @new_email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:user_id]

    # I can still use the old email to authenticate
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal @email, jar.encrypted[:email]

    # When get the confirmation code from the email, I can use the new email
    code = EmailVerificationCode.find_by_cleartext(@new_email)
    post '/email', params: { email: @new_email, email_verification_code: code.code }
    assert_redirected_to dashboard_path
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal @new_email, jar.encrypted[:email]

    # When I log in again with the new email, it works
    post '/authenticate', params: { email: @new_email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal @new_email, jar.encrypted[:email]

    # Can still read personal data
    vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
    user_id = jar.encrypted[:user_id]
    personal_data = Authentication::Vault.personal_data(user_id, vault_key)
    assert personal_data

    # I can not use the old email to authenticate
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:user_id]

  end

  test 'changing email to email already taken and verified' do
    @email = 'hello@example.com'
    @new_email = 'hello@world.com'
    @old_password = 'old'
    Authentication::Services::Authenticate.new(email: @email, password: @old_password).register!
    Authentication::Services::Authenticate.new(email: @new_email, password: @old_password).register!

    # Log in with the old email
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    assert_equal @email, jar.encrypted[:email]

    post '/email', params: { email: @new_email }
    assert_response :redirect

    # When get the confirmation code from the email, I can use the new email
    code = EmailVerificationCode.find_by_cleartext(@new_email)
    post '/email', params: { email: @new_email, email_verification_code: code.code }
    assert_redirected_to dashboard_path
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal @email, jar.encrypted[:email]
  end

  test 'failing when no email provided' do
    @email = 'hello@world.com'
    @old_password = 'old'
    Authentication::Services::Authenticate.new(email: @email, password: @old_password).register!

    # Log in with the old email
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }

    post '/email', params: { email: " " }
    assert_redirected_to edit_email_path
  end

  test 'failing when wrong code' do
    @email = 'hello@example.com'
    @new_email = 'hello@world.com'
    @old_password = 'old'
    Authentication::Services::Authenticate.new(email: @email, password: @old_password).register!

    # Log in with the old email
    post '/authenticate', params: { email: @email, password: @old_password, remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    assert_equal @email, jar.encrypted[:email]

    post '/email', params: { email: @new_email }
    assert_response :redirect

    # When get the confirmation code from the email, I can use the new email
    # code = EmailVerificationCode.find_by_cleartext(@new_email)
    post '/email', params: { email: @new_email, email_verification_code: "a" }
    assert_redirected_to verify_email_path(email: @new_email, email_verification_code: "a")
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal @email, jar.encrypted[:email]
  end
end
