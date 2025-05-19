require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test 'the login screen' do
    get new_registration_url
    assert_response :success

    assert_select 'input#email'
  end

  test 'redirect to turnstile' do
    post registrations_url, params: { email: 'hello@world.com' }
    assert_redirected_to verify_human_registrations_url(email: 'hello@world.com')
  end

  test 'redirect to password if known' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post registrations_url, params: { email: 'hello@world.com' }
    assert_redirected_to verify_password_url(email: 'hello@world.com')
  end

  test 'redirect to password if known and now upcase' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post registrations_url, params: { email: 'Hello@world.com' }
    assert_redirected_to verify_password_url(email: 'Hello@world.com')
  end

  test 'redirect to password if known and then upcase' do
    Authentication::Services::Authenticate.new(email: 'Hello@world.com', password: 'secret').register!
    post registrations_url, params: { email: 'hello@world.com' }
    assert_redirected_to verify_password_url(email: 'hello@world.com')
  end

  test 'redirect to code if mail sent' do
    post verify_human_registrations_url, params: { email: 'hello@world.com' }
    post registrations_url, params: { email: 'hello@world.com' }
    assert_redirected_to verify_email_registrations_url(email: 'hello@world.com')
  end

  # test 'redirect to create password if e-mail is verified' do
  #   post verify_human_registrations_url, params: { email: 'hello@world.com' }
  #   code = EmailVerificationCode.find_by_cleartext('hello@world.com')
  #   post verify_email_registrations_url(email: 'hello@world.com', email_verification_code: code.code)
  #
  #   post registrations_url, params: { email: 'hello@world.com' }
  #   assert_redirected_to create_password_registrations_url(email: 'hello@world.com',
  #                                                          email_verification_code: code.code)
  # end

  test 'handle wrong email' do
    email = 'hello@gmail.dk'
    # Let's mock the email sending:
    mock = Minitest::Mock.new
    mock.expect(:generate_and_send_verification_code!, nil) do
      raise Net::SMTPFatalError, 'Hello'
    end
    Authentication::Services::PrepareEmailForValidation.stub :new, mock do
      post verify_human_registrations_url, params: { email: email }
    end
    assert_response :success
  end

  test 'the flow from human verification' do
    # If no code given
    post verify_human_registrations_url, params: { email: 'hello@world.com' }
    assert_redirected_to verify_email_registrations_url(email: 'hello@world.com')

    email = ActionMailer::Base.deliveries.last
    assert email

    code = EmailVerificationCode.find_by_cleartext('hello@world.com')
    assert code
    assert_includes email.html_part.body.to_s, code.code

    # If I try to verify with the wrong code, it will send a new one
    post verify_email_registrations_url(email: 'hello@world.com', email_verification_code: 'wrong')
    assert_response :success

    new_email = ActionMailer::Base.deliveries.last
    new_code = EmailVerificationCode.find_by_cleartext('hello@world.com')
    assert_not_equal code.code, new_code.code
    assert_includes new_email.html_part.body.to_s, new_code.code

    # Now I will verify with the correct code
    post verify_email_registrations_url(email: 'hello@world.com', email_verification_code: new_code.code)
    assert_redirected_to create_password_registrations_url(email: 'hello@world.com',
                                                           email_verification_code: new_code.code)

    # If I provide almost blank password:
    post create_password_registrations_url(email: 'hello@world.com', email_verification_code: new_code.code,
                                           password: ' ', password_confirmation: ' ')
    assert_response :success

    # If they don't match
    post create_password_registrations_url(email: 'hello@world.com', email_verification_code: new_code.code,
                                           password: 'a', password_confirmation: 'b')
    assert_response :success

    # If I provide a good password and a client id
    Authentication::RelyingParty.stub :fetch, nil do
      post create_password_registrations_url(
        email: 'hello@world.com',
        email_verification_code: new_code.code,
        password: 'secret',
        password_confirmation: 'secret',
        client_id: 'oase.app',
        remember_me: 1
      )
      assert_redirected_to confirm_path(client_id: 'oase.app')

      # And we are logged in
      jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
      user_id = jar.encrypted[:user_id]
      vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
      email = jar.encrypted[:email]

      assert_equal 'hello@world.com', email
      assert Authentication::Vault.personal_data(user_id, vault_key)

      # And we record that the email was verified
      hashed_email = Authentication::HashedEmail.find_by_cleartext('hello@world.com')
      assert hashed_email.email_verified_at
    end
  end

  test 'session login resets' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post authenticate_url,
         params: { email: 'hello@world.com', password: 'secret' }
    assert_redirected_to confirm_path

    get login_url
    assert_response :success

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    user_id = jar.encrypted[:user_id]
    assert_nil user_id
  end

  test 'cookie login persists' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post authenticate_url,
         params: { email: 'hello@world.com', password: 'secret', remember_me: 1 }
    assert_redirected_to confirm_path

    get login_url
    assert_response :redirect
  end

  test 'cookie login overruled with prompt=login' do
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post authenticate_url,
         params: { email: 'hello@world.com', password: 'secret', remember_me: 1 }
    assert_redirected_to confirm_path

    url = login_url(prompt: 'login')
    get url
    assert_response :success
  end
end
