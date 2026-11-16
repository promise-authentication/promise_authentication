require 'test_helper'

class Authentication::Services::PrepareEmailForValidationTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::PrepareEmailForValidation
    # Deliveries accumulate across the tests sharing this process — the
    # absolute size assertion below is only meaningful from a clean slate.
    ActionMailer::Base.deliveries.clear
  end

  test 'it should be valid' do
    relying_party_id = 'world.com'
    relying_party = Minitest::Mock.new
    relying_party.expect :knows_legacy_account?, false, []
    relying_party.expect :id, relying_party_id
    relying_party.expect :locale, nil
    relying_party.expect :name, 'RelyingPartyZ'
    relying_party.expect :name, 'RelyingPartyZ'
    # I'm not sure why this is needed: ~AL
    relying_party.expect :is_a?, false, [Hash]
    relying_party.expect :is_a?, false, [Array]

    inst = @described_class.new(
      email: 'hello@world.com',
      relying_party: relying_party
    )
    inst.generate_and_send_verification_code!

    code = EmailVerificationCode.last
    assert_equal EmailVerificationCode.count, 1
    assert_equal EmailVerificationCode.find_by_cleartext('hello@world.com').code, code.code

    assert_equal inst.verify!(code.code), true
    assert_equal inst.verify!('dakj'), false

    # Test that the email was sent:
    email = ActionMailer::Base.deliveries.last
    assert_not_nil email
    assert_includes email.body.encoded, code.code
    assert_equal email.subject, EmailVerificationMailer.subject_for(code: code.code, relying_party_name: 'RelyingPartyZ')
    assert_equal email.header['From'].value, 'RelyingPartyZ via Promise <hello@promiseauthentication.org>'

    # When I call it again, it should reset and send new mail
    inst.generate_and_send_verification_code!(old_code: code.code)
    new_code = EmailVerificationCode.last
    assert_equal EmailVerificationCode.count, 1
    assert_equal EmailVerificationCode.find_by_cleartext('hello@world.com').code, new_code.code

    assert_not_equal code.code, new_code.code
    assert_not_equal code.created_at, new_code.created_at

    new_email = ActionMailer::Base.deliveries.last
    assert_not_nil new_email
    assert_includes new_email.body.encoded, new_code.code

    assert_equal ActionMailer::Base.deliveries.size, 2
  end

  test 'in development the magic link is logged so the flow works without mail' do
    logged = []
    Rails.stub :env, ActiveSupport::EnvironmentInquirer.new('development') do
      Rails.logger.stub :info, ->(line) { logged << line } do
        @described_class.new(email: 'dev@example.com', login_configuration: {})
                        .generate_and_send_verification_code!
      end
    end

    logged = logged.grep(/magic-link/)
    assert_equal 1, logged.size
    assert_match %r{\A\[magic-link\] dev@example.com: http\S+/registrations/magic\?token=\S+\z}, logged.first
  end

  # Delivers on the given attempt; times out on the ones before it.
  def mailer_timing_out_until(succeeding_attempt)
    attempts = 0
    mail = Object.new
    mail.define_singleton_method(:deliver_now) do
      attempts += 1
      raise Net::OpenTimeout if attempts < succeeding_attempt
    end
    mailer = Object.new
    mailer.define_singleton_method(:verify_email) { mail }
    [->(**) { mailer }, -> { attempts }]
  end

  test 'a mail server timeout is retried with growing pauses' do
    with, attempts = mailer_timing_out_until(3)
    service = @described_class.new(email: 'slow@example.com')
    pauses = []

    EmailVerificationMailer.stub :with, with do
      service.stub :sleep, ->(seconds) { pauses << seconds } do
        assert service.generate_and_send_verification_code!
      end
    end

    assert_equal 3, attempts.call
    assert_equal [2, 4], pauses
  end

  test 'a mail server that keeps timing out gives up after three retries' do
    with, attempts = mailer_timing_out_until(100)
    service = @described_class.new(email: 'slow@example.com')

    EmailVerificationMailer.stub :with, with do
      service.stub :sleep, nil do
        assert_raises(Net::OpenTimeout) { service.generate_and_send_verification_code! }
      end
    end

    assert_equal 4, attempts.call
  end
end
