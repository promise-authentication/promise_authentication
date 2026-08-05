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
    url = text[%r{https?://\S+/registrations/magic/\S+}]
    assert url, 'expected the mail to contain a magic link'
    URI.parse(url).path
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
    get "/registrations/magic/#{SecureRandom.hex(16)}.#{SecureRandom.urlsafe_base64(32)}"

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

  test 'the change-email flow does not get a magic link' do
    send_verification_mail!(login_configuration: nil)

    mail = ActionMailer::Base.deliveries.last
    assert_no_match %r{/registrations/magic/}, mail.text_part.body.to_s
    assert_no_match %r{/registrations/magic/}, mail.html_part.body.to_s
  end
end
