require 'test_helper'

class Authentication::IdentifierTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Identifier
  end

  test 'rejects unknown types' do
    assert_raises Authentication::Identifier::InvalidType do
      @described_class.new(type: :carrier_pigeon, value: 'x')
    end
  end

  test 'digest handles nil' do
    assert_nil @described_class.digest(nil)
  end

  test 'digest returns the historical UTF-8 hash for e-mails' do
    string = @described_class.email('hello@example.com').digest
    assert_equal 'F1O9s2gnGnhYh92/uSYWTy98aoj2CcB/8EAcVXKVUgabnIiDlRJDlj1IZIOeIDFRujyyosNPc9Zwhoi7WzRElsKpYgVAPB3es0qOl5nQWRN6L0LnDrQ4Xw3v4hSHWlWG', string
    assert_equal 128, string.size
    assert_equal Encoding::UTF_8, string.encoding
  end

  test 'e-mail digest is deterministic and normalised' do
    a = @described_class.email('Hello@Example.com ').digest
    b = @described_class.email('hello@example.com').digest
    assert_equal a, b
  end

  test 'e-mail digests differ for different e-mails' do
    refute_equal @described_class.email('a@example.com').digest,
                 @described_class.email('b@example.com').digest
  end

  test 'normalises phone numbers to E.164' do
    assert_equal '+4520123456', @described_class.phone('20 12 34 56').value
    assert_equal '+4520123456', @described_class.phone('+45 20 12 34 56').value
  end

  test 'same phone number always digests the same regardless of formatting' do
    a = @described_class.phone('20123456').digest
    b = @described_class.phone('+45 20 12 34 56').digest
    assert_equal a, b
  end

  test 'unparseable phone numbers normalise by stripping all whitespace' do
    spaced = @described_class.phone('00 00 00')
    refute spaced.valid?, 'precondition: should not be a valid number'
    assert_equal '000000', spaced.value
    assert_equal @described_class.phone('000000').digest, spaced.digest
  end

  test 'phone and e-mail digests do not collide' do
    refute_equal @described_class.email('hello@example.com').digest,
                 @described_class.phone('+4520123456').digest
  end

  test 'valid? for e-mail' do
    assert @described_class.email('hello@world.com').valid?
    refute @described_class.email('not-an-email').valid?
    refute @described_class.email('').valid?
  end

  test 'valid? for phone' do
    assert @described_class.phone('+4520123456').valid?
    refute @described_class.phone('123').valid?
    refute @described_class.phone('').valid?
  end

  test 'equality by type and value' do
    assert_equal @described_class.email('a@b.com'), @described_class.email('A@b.com')
    refute_equal @described_class.email('a@b.com'), @described_class.phone('+4520123456')
  end
end
