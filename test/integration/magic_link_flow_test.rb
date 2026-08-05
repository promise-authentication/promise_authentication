require 'test_helper'

class MagicLinkFlowTest < ActionDispatch::IntegrationTest
  EMAIL = 'new-user@example.com'.freeze
  LOGIN_CONFIGURATION = {
    'redirect_uri' => 'https://rp.example.com/callback?state=secret',
    'nonce' => 'some-nonce'
  }.freeze

  setup do
    ActionMailer::Base.deliveries.clear
  end

  def send_verification_mail!(login_configuration: LOGIN_CONFIGURATION)
    Authentication::Services::PrepareEmailForValidation.new(
      email: EMAIL,
      login_configuration: login_configuration
    ).generate_and_send_verification_code!
  end

  def magic_path_from_mail
    mail = ActionMailer::Base.deliveries.last
    text = mail.text_part.body.to_s
    url = text[%r{https?://\S+/registrations/magic\?token=\S+}]
    assert url, 'expected the mail to contain a magic link'
    uri = URI.parse(url)
    "#{uri.path}?#{uri.query}"
  end

  test 'the mail contains a magic link that lands on create_password' do
    send_verification_mail!
    code = EmailVerificationCode.find_by_cleartext(EMAIL).code

    get magic_path_from_mail

    assert_redirected_to create_password_registrations_path(
      LOGIN_CONFIGURATION.merge('email' => EMAIL, 'email_verification_code' => code)
    )

    follow_redirect!
    assert_response :success
  end

  test 'the mail also still contains the code' do
    send_verification_mail!
    code = EmailVerificationCode.find_by_cleartext(EMAIL).code

    assert_includes ActionMailer::Base.deliveries.last.text_part.body.to_s, code
  end

  test 'an unknown or tampered token redirects to login' do
    get magic_registration_path(token: "#{SecureRandom.hex(16)}.#{SecureRandom.urlsafe_base64(32)}")

    assert_redirected_to login_path
    assert_equal I18n.t('magic_link_invalid'), flash[:error]
  end

  test 'a stale link is invalidated when a new code is sent' do
    send_verification_mail!
    stale_path = magic_path_from_mail

    send_verification_mail!

    get stale_path

    assert_redirected_to login_path
    assert_equal I18n.t('magic_link_invalid'), flash[:error]
  end

  test 'link and code expire together' do
    send_verification_mail!
    path = magic_path_from_mail
    expired = (EmailVerificationCode::TTL + 1.minute).ago
    EmailVerificationCode.find_by_cleartext(EMAIL).update!(created_at: expired)
    MagicLink.last.update!(created_at: expired)

    get path
    assert_redirected_to login_path
    assert_equal I18n.t('magic_link_invalid'), flash[:error]

    assert_nil EmailVerificationCode.active_for_cleartext(EMAIL)
  end

  test 'an expired but undeleted code lets the user restart with context intact' do
    send_verification_mail!
    path = magic_path_from_mail
    EmailVerificationCode.find_by_cleartext(EMAIL).update!(
      created_at: (EmailVerificationCode::TTL + 1.minute).ago
    )

    get path

    assert_redirected_to login_path(LOGIN_CONFIGURATION.merge('email' => EMAIL))
    assert_equal I18n.t('magic_link_invalid'), flash[:error]
  end

  test 'wrong codes only trigger a limited number of resent mails' do
    send_verification_mail!
    max = Authentication::Services::PrepareEmailForValidation::MAX_RESENDS

    (max + 3).times do
      post verify_email_registrations_path(email: EMAIL, email_verification_code: '????')
      assert_response :success
    end

    # 1 initial mail + at most MAX_RESENDS resends, then it stops
    assert_equal 1 + max, ActionMailer::Base.deliveries.size
  end

  test 'the change-email flow does not get a magic link' do
    send_verification_mail!(login_configuration: nil)

    mail = ActionMailer::Base.deliveries.last
    assert_no_match %r{/registrations/magic}, mail.text_part.body.to_s
    assert_no_match %r{/registrations/magic}, mail.html_part.body.to_s
  end
end
