require 'test_helper'

class VerificationCodeTest < ActiveSupport::TestCase
  setup do
    @described_class = VerificationCode
  end

  test 'human readable code respects the range' do
    klass = @described_class::HumanReadableCode
    100.times do
      generated = klass.generate(2..6)
      assert_kind_of String, generated
      assert generated.length.between?(2, 6), "#{generated} is #{generated.length} chars"
    end
  end

  test 'find_for returns the code for an identifier' do
    identifier = Authentication::Identifier.phone('+4520123456')
    @described_class.create!(id: identifier.digest, code: 'abcd')

    assert_equal 'abcd', @described_class.find_for(identifier).code
  end

  test 'find_for returns nil when absent' do
    assert_nil @described_class.find_for(Authentication::Identifier.phone('+4520999999'))
  end

  test 'EmailVerificationCode shim looks up by cleartext e-mail' do
    identifier = Authentication::Identifier.email('hello@world.com')
    @described_class.create!(id: identifier.digest, code: 'wxyz')

    assert_equal 'wxyz', EmailVerificationCode.find_by_cleartext('hello@world.com').code
  end
end
