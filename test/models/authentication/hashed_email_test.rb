require 'test_helper'

class Authentication::HashedEmailTest < ActiveSupport::TestCase

  setup do
    @described_class = Authentication::HashedEmail
    @user_id = 'uid'
    @hashed_email = @described_class.new id: 'hello', user_id: @user_id
  end

  test 'no key raises' do
    @hashed_email.id = nil
    assert_raises ActiveRecord::NotNullViolation do
      @hashed_email.save!
    end
  end

  test 'requires user_id' do
    @hashed_email.user_id = nil
    assert_raises ActiveRecord::RecordInvalid do
      @hashed_email.save!
    end
  end

  test 'duplicate key raises' do
    @described_class.create @hashed_email.attributes
    assert_raises ActiveRecord::RecordNotUnique do
      @hashed_email.save!
    end
  end

  test 'from_cleartext handles nil' do
    assert_nil @described_class.from_cleartext(nil)
  end

  test 'returns UTF-8 encoded string' do
    string = @described_class.from_cleartext('hello@example.com')
    assert_equal Encoding::UTF_8, string.encoding
    assert_equal "1753bdb368271a785887ddbfb926164f2f7c6a88f609c07ff0401c55729552069b9c8883951243963d4864839e203151ba3cb2a2c34f73d6708688bb5b344496c2a96205403c1ddeb34a8e9799d059137a2f42e70eb4385f0defe214875a5586", string
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
    @hashed_email.id = id
    @hashed_email.save

    assert_equal @user_id, @described_class.user_id_for_cleartext(email)
  end

end
