require 'test_helper'

class Authentication::Services::PrepareEmailForValidationTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::PrepareEmailForValidation
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
    assert_equal email.subject, "RelyingPartyZ - Your code: #{code.code}"
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
end
