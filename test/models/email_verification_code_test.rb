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

class EmailVerificationCodeBounceTest < ActiveSupport::TestCase
  Report = Struct.new(:token, :recipient_hashes, :reason, keyword_init: true)

  def pending(email, token: nil)
    EmailVerificationCode.create!(id: Authentication::HashedEmail.from_cleartext(email), code: 'ab7k', delivery_token: token)
  end

  test 'a report with a matching token marks that code' do
    code = pending('hello@world.com', token: 'tok_1234567890abcdefgh')
    assert_equal code, EmailVerificationCode.record_bounce!(Report.new(token: 'tok_1234567890abcdefgh', recipient_hashes: [], reason: 'mailbox_full'))
    assert code.reload.bounced?
    assert_equal 'mailbox_full', code.bounce_reason
    assert code.mail_certainly_undelivered?
  end

  test 'a report whose token matches nothing is moot even if the recipient has a newer code' do
    code = pending('hello@world.com', token: 'tok_new_567890abcdefgh')
    report = Report.new(token: 'tok_old_567890abcdefgh', recipient_hashes: [code.id], reason: 'rejected')
    assert_nil EmailVerificationCode.record_bounce!(report)
    assert_not code.reload.bounced?
  end

  test 'a report without a token falls back to the hashed recipient' do
    code = pending('hello@world.com')
    report = Report.new(token: nil, recipient_hashes: [Authentication::HashedEmail.from_cleartext('Hello@World.com')], reason: 'rejected')
    assert_equal code, EmailVerificationCode.record_bounce!(report)
    assert code.reload.bounced?
    assert_not code.mail_certainly_undelivered?
  end

  test 'expired codes are not marked' do
    code = pending('hello@world.com', token: 'tok_1234567890abcdefgh')
    code.update_column(:created_at, 2.hours.ago)
    assert_nil EmailVerificationCode.record_bounce!(Report.new(token: 'tok_1234567890abcdefgh', recipient_hashes: [], reason: 'other'))
  end

  test 'an unknown reason is stored as other, and a second bounce does not overwrite the first' do
    code = pending('hello@world.com')
    code.mark_bounced!('weird')
    assert_equal 'other', code.bounce_reason
    code.mark_bounced!('mailbox_full')
    assert_equal 'other', code.reload.bounce_reason
  end
end
