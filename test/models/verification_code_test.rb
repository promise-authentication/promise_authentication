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

  test 'verify matches the right code, case-insensitively' do
    code = @described_class.create!(id: 'x', code: 'abcd')

    assert code.verify('abcd')
    assert code.verify('ABCD')
    assert code.verify(' abcd ')
  end

  test 'verify counts wrong guesses and burns the code after MAX_ATTEMPTS' do
    code = @described_class.create!(id: 'x', code: 'abcd')

    (@described_class::MAX_ATTEMPTS - 1).times { assert_not code.verify('zzzz') }
    assert_equal @described_class::MAX_ATTEMPTS - 1, code.attempts

    assert_not code.verify('zzzz') # the final allowed guess burns the code
    assert_not @described_class.exists?('x')
  end

  test 'verify rejects an expired code' do
    code = @described_class.create!(id: 'x', code: 'abcd')

    travel(@described_class::EXPIRES_AFTER + 1.minute) do
      assert_not code.verify('abcd')
    end
  end

  test 'find_for ignores and cleans up an expired code' do
    identifier = Authentication::Identifier.phone('+4520123456')
    @described_class.create!(id: identifier.digest, code: 'abcd')

    travel(@described_class::EXPIRES_AFTER + 1.minute) do
      assert_nil @described_class.find_for(identifier)
    end
    assert_not @described_class.exists?(identifier.digest)
  end
end
