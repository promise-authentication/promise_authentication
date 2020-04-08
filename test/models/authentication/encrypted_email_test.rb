require 'test_helper'

class Authentication::EncryptedEmailTest < ActiveSupport::TestCase

  setup do
    @described_class = Authentication::EncryptedEmail
    @user_id = 'uid'
    @encrypted_email = @described_class.new id: 'hello', user_id: @user_id
  end

  test 'no key raises' do
    @encrypted_email.id = nil
    assert_raises ActiveRecord::NotNullViolation do
      @encrypted_email.save!
    end
  end

  test 'requires user_id' do
    @encrypted_email.user_id = nil
    assert_raises ActiveRecord::RecordInvalid do
      @encrypted_email.save!
    end
  end

  test 'duplicate key raises' do
    @described_class.create @encrypted_email.attributes
    assert_raises ActiveRecord::RecordNotUnique do
      @encrypted_email.save!
    end
  end

  test 'from_cleartext handles nil' do
    assert_nil @described_class.from_cleartext(nil)
  end

  test 'returns UTF-8 encoded string' do
    string = @described_class.from_cleartext('hello')
    assert_equal Encoding::UTF_8, string.encoding
    assert_equal ",\xF2M\xBA_\xB0\xA3\u000E&\xE8;*Ź\xE2\x9E\e\u0016\u001E\\\u001F\xA7B^s\u00043b\x93\x8B\x98$\xE4ϣ\x9A=7\xBE1Ŗ\t\xE8\a\x97\a\x99ʦ\x8A\u0019\xBF\xAA\u0015\u0013_\u0016P\x85\xE0\u001DA\xA6[\xA1\xE1\xB1F\xAE\xB6\xBD\u0000\x92\xB4\x9E\xAC!L\u0010<ϣ\xA3e\x95K\xBB\xE5/t\xA2\xB3b\f\x94", string
  end

  test 'from_cleartext' do
    email1 = 'hello@example.com'
    email2 = 'hello@world.com'
    encrypted1 = @described_class.from_cleartext(email1)
    encrypted1b = @described_class.from_cleartext(email1)
    encrypted2 = @described_class.from_cleartext(email2)
    assert_equal encrypted1, encrypted1b
    assert_not_equal email1, encrypted1
    assert_not_equal email2, encrypted2
    assert_not_equal encrypted1, encrypted2
  end

  test 'user_id_for_cleartext when not present' do
    assert_nil @described_class.user_id_for_cleartext('someone@notthere.com')
  end

  test 'user_id_for_cleartext when present' do
    email = 'hello@example.com'
    id = @described_class.from_cleartext(email)
    @encrypted_email.id = id
    @encrypted_email.save

    assert_equal @user_id, @described_class.user_id_for_cleartext(email)
  end

end
