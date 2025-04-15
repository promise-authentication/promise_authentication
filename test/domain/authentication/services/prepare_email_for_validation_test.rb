require 'test_helper'

class Authentication::Services::PrepareEmailForValidationTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::PrepareEmailForValidation
  end

  test 'it should be valid' do
    inst = @described_class.new(
      email: 'hello@world.com'
    )

    inst.generate_and_send_verification_code!

    code = EmailVerificationCode.last
    assert_equal EmailVerificationCode.count, 1
    assert_equal EmailVerificationCode.find_by_cleartext('hello@world.com').code, code.code

    assert_equal inst.verify!(code.code), true
    assert_equal inst.verify!('dakj'), false
  end
end
