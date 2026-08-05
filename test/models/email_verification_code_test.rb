require 'test_helper'

class EmailVerificationCodeTest < ActiveSupport::TestCase
  setup do
    @described_class = EmailVerificationCode
  end

  test 'human readable code' do
    klass = @described_class::HumanReadableCode
    100.times do
      generated = klass.generate(2..6)
      assert_equal generated.class, String
      assert generated.length >= 2 && generated.length <= 6,
             "Length should be between 2 and 6 but #{generated} is #{generated.length}"
    end
  end

  test 'human readable code with fixed length' do
    klass = @described_class::HumanReadableCode
    generated = klass.generate(4..4)
    assert_equal generated.length, 4
  end

  test 'active_for_cleartext ignores expired codes' do
    email = 'ttl-test@example.com'
    @described_class.create!(
      id: Authentication::HashedEmail.from_cleartext(email),
      code: 'abcd'
    )

    assert_not_nil @described_class.active_for_cleartext(email)

    @described_class.find_by_cleartext(email).update!(
      created_at: (@described_class::TTL + 1.minute).ago
    )

    assert_nil @described_class.active_for_cleartext(email)
    assert_not_nil @described_class.find_by_cleartext(email)
  end

  test 'sweep_expired! deletes only expired codes' do
    fresh = 'fresh@example.com'
    old = 'old@example.com'
    @described_class.create!(id: Authentication::HashedEmail.from_cleartext(fresh), code: 'abcd')
    @described_class.create!(id: Authentication::HashedEmail.from_cleartext(old), code: 'abcd')
    @described_class.find_by_cleartext(old).update!(
      created_at: (@described_class::TTL + 1.minute).ago
    )

    @described_class.sweep_expired!

    assert_not_nil @described_class.find_by_cleartext(fresh)
    assert_nil @described_class.find_by_cleartext(old)
  end
end
