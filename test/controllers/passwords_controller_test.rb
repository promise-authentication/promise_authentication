require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test 'changing password' do
    @email = 'hello@example.com'
    @old_password = 'old'
    Authentication::Services::Authenticate.new(email: @email, password: @old_password).register!
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

  test 'recovering a password with a phone number uses an SMS code' do
    Authentication::Services::SmsSender.reset!
    phone = '+4520123456'
    identifier = Authentication::Identifier.phone(phone)
    auth = Authentication::Services::Authenticate.new(phone: phone, password: 'old')
    auth.register!

    # Request recovery by phone -> code by SMS, redirect to code entry
    post '/password/recover', params: { phone: phone }
    assert_redirected_to recover_code_password_path

    code = VerificationCode.find_for(identifier)
    assert code
    sms = Authentication::Services::SmsSender.deliveries.last
    assert_equal phone, sms[:to]
    assert_includes sms[:body], code.code
    assert_empty ActionMailer::Base.deliveries

    # A wrong code re-renders
    post '/password/recover_code', params: { verification_code: 'nope' }
    assert_response :success

    # The right code moves on to the reset form
    post '/password/recover_code', params: { verification_code: code.code }
    assert_redirected_to reset_password_path

    # Set a new password
    post '/password/reset', params: { new_password: 'brandnew' }
    assert_redirected_to login_path

    # Old password no longer works, the new one does
    assert_raises Authentication::Password::NotMatching do
      Authentication::Services::Authenticate::Existing.call(identifier, 'old')
    end
    uid, key = Authentication::Services::Authenticate::Existing.call(identifier, 'brandnew')
    assert_equal auth.user_id, uid
    assert key
  end

  test 'recovering with an unknown phone number reveals nothing and sends no SMS' do
    Authentication::Services::SmsSender.reset!
    post '/password/recover', params: { phone: '+4520000000' }
    assert_redirected_to recover_code_password_path
    assert_empty Authentication::Services::SmsSender.deliveries
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
    auth.register!

    assert_emails 1 do
      post '/password/recover', params: { email: @email }
      token = Authentication::RecoveryToken.where(user_id: auth.user_id).last.token
      email = ActionMailer::Base.deliveries.first
      assert_includes email.to, @email
      assert_includes email.html_part.body.to_s, token
      assert_includes email.text_part.body.to_s, token
      assert_includes email.subject.to_s, 'Promise'
    end
    assert_redirected_to wait_password_path
  end

  test 'recovering password when mail present and there is a client id' do
    @email = 'hello@example.com'
    @old_password = 'old'
    auth = Authentication::Services::Authenticate.new(
      email: @email,
      password: @old_password
    )
    auth.register!

    relying_party_id = 'example.com'
    relying_party = Minitest::Mock.new
    relying_party.expect :knows_legacy_account?, false, []
    relying_party.expect :id, relying_party_id
    relying_party.expect :locale, nil
    relying_party.expect :name, 'Sandbox'
    # I'm not sure why this is needed: ~AL
    relying_party.expect :is_a?, false, [Hash]
    relying_party.expect :is_a?, false, [Array]

    Authentication::RelyingParty.stub :find, relying_party do
      assert_emails 1 do
        post '/password/recover', params: { email: @email, client_id: relying_party_id }
        token = Authentication::RecoveryToken.where(user_id: auth.user_id).last.token
        email = ActionMailer::Base.deliveries.first
        assert_includes email.to, @email
        assert_includes email.subject.to_s, 'Sandbox'
        assert_includes email.subject.to_s, 'Promise'
        assert_includes email.html_part.body.to_s, token
        assert_includes email.text_part.body.to_s, token
        assert_includes email.html_part.body.to_s, 'Sandbox'
        assert_includes email.text_part.body.to_s, 'Sandbox'
      end
      assert_redirected_to wait_password_path(client_id: relying_party_id)
    end
  end
end
