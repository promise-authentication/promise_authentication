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

  def sign_in(email = 'hello@example.com')
    Authentication::Services::Authenticate.new(email: email, password: 'old').register!
    post '/authenticate', params: { email: email, password: 'old', remember_me: 1 }
  end

  def send_code(email)
    Authentication::Services::PrepareEmailForValidation.new(email: email).generate_and_send_verification_code!
    EmailVerificationCode.find_by_cleartext(email)
  end

  test 'verify without a pending code sends a visitor to login' do
    get '/email/verify', params: { email: 'nobody@example.com' }
    assert_redirected_to login_path(email: 'nobody@example.com')
  end

  test 'verify without a pending code sends a signed-in user to confirm' do
    sign_in
    get '/email/verify', params: { email: 'nobody@example.com' }
    assert_redirected_to confirm_path
  end

  test 'verify shows the code form when a code is pending' do
    code = send_code('new@example.com')
    get '/email/verify', params: { email: 'new@example.com' }
    assert_response :success
    assert_select "input[name=email_verification_code][placeholder='#{code.code.first}...']"
  end

  test 'posting the right code moves on to create password' do
    code = send_code('new@example.com')
    post '/email/verify', params: { email: 'new@example.com', email_verification_code: code.code.downcase }
    assert_redirected_to create_password_registrations_path(email: 'new@example.com',
                                                            email_verification_code: code.code.downcase)
  end

  test 'posting a wrong code resends a new code' do
    code = send_code('new@example.com')
    post '/email/verify', params: { email: 'new@example.com', email_verification_code: 'nope' }
    assert_response :success
    assert flash[:resent_code]
    assert_not_equal code.code, EmailVerificationCode.find_by_cleartext('new@example.com').code
  end

  test 'posting a wrong code after too many resends shows an error' do
    send_code('new@example.com')
    EmailVerificationCode.find_by_cleartext('new@example.com')
                         .update!(resend_count: Authentication::Services::PrepareEmailForValidation::MAX_RESENDS)
    post '/email/verify', params: { email: 'new@example.com', email_verification_code: 'nope' }
    assert_response :success
    assert_equal I18n.t('too_many_codes_sent'), flash[:error]
  end

  test 'changing email with a code but no new email fails' do
    sign_in
    post '/email', params: { email_verification_code: 'abcd' }
    assert_redirected_to dashboard_path
    assert_equal I18n.t('error_changing_email'), flash[:error]
  end

  test 'changing email fails gracefully when the change does not go through' do
    sign_in
    change_request = Authentication::Services::ChangeEmail.new(from_email: 'a@b.c', to_email: 'd@e.f',
                                                               confirmation_code: 'abcd')
    change_request.define_singleton_method(:call) { false }
    Authentication::Services::ChangeEmail.stub :new, ->(*) { change_request } do
      post '/email', params: { email: 'd@e.f', email_verification_code: 'abcd' }
    end
    assert_redirected_to dashboard_path
    assert_equal I18n.t('error_changing_email'), flash[:error]
  end
end
