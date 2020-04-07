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
  end

  test 'user_id_for_cleartext when present' do
    email = 'hello@example.com'
    id = @described_class.from_cleartext(email)
    @encrypted_email.id = id
    @encrypted_email.save

    assert_equal @user_id, @described_class.user_id_for_cleartext(email)
  end

end
