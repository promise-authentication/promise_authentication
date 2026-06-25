require 'test_helper'

class Authentication::Services::PrepareIdentifierForValidationTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::PrepareIdentifierForValidation
    Authentication::Services::SmsSender.reset!
    ActionMailer::Base.deliveries.clear
  end

  test 'e-mail identifiers are delivered by mail' do
    service = @described_class.new(identifier: Authentication::Identifier.email('hello@world.com'))
    code = service.generate_and_send_verification_code!

    assert code.present?
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal 0, Authentication::Services::SmsSender.deliveries.size
    assert service.verify!(code.code)
  end

  test 'phone identifiers are delivered by SMS, including the code' do
    service = @described_class.new(identifier: Authentication::Identifier.phone('+4520123456'))
    code = service.generate_and_send_verification_code!

    assert code.present?
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal 1, Authentication::Services::SmsSender.deliveries.size

    sms = Authentication::Services::SmsSender.deliveries.last
    assert_equal '+4520123456', sms[:to]
    assert_includes sms[:body], code.code
  end

  test 'verify! is case insensitive and rejects wrong/blank codes' do
    service = @described_class.new(identifier: Authentication::Identifier.phone('+4520123456'))
    code = service.generate_and_send_verification_code!

    assert service.verify!(code.code.upcase)
    refute service.verify!('zzzz')
    refute service.verify!(nil)
    refute service.verify!('')
  end

  test 'regenerating with an old code avoids reusing the first character' do
    service = @described_class.new(identifier: Authentication::Identifier.phone('+4520123456'))
    first = service.generate_and_send_verification_code!
    second = service.generate_and_send_verification_code!(old_code: first.code)

    refute_equal first.code[0], second.code[0]
  end

  test 'reset! removes the outstanding code' do
    service = @described_class.new(identifier: Authentication::Identifier.email('hello@world.com'))
    service.generate_and_send_verification_code!
    assert service.verifier

    service.reset!
    assert_nil service.verifier
  end
end
