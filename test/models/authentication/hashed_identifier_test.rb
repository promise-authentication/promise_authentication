require 'test_helper'

class Authentication::HashedIdentifierTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::HashedIdentifier
    @user_id = 'uid'
    @identifier = Authentication::Identifier.email('hello@example.com')
    @record = @described_class.new(id: @identifier.digest, identifier_type: 'email', user_id: @user_id)
  end

  test 'no key raises' do
    @record.id = nil
    assert_raises ActiveRecord::NotNullViolation do
      @record.save!
    end
  end

  test 'requires user_id' do
    @record.user_id = nil
    assert_raises ActiveRecord::RecordInvalid do
      @record.save!
    end
  end

  test 'duplicate key raises' do
    @described_class.create @record.attributes
    assert_raises ActiveRecord::RecordNotUnique do
      @record.save!
    end
  end

  test 'email_verified_at aliases verified_at' do
    time = Time.zone.now
    @record.email_verified_at = time
    assert_equal time, @record.verified_at
  end

  test 'find_by_identifier when present' do
    @record.save!
    assert_equal @record, @described_class.find_by_identifier(@identifier)
  end

  test 'user_id_for when not present' do
    assert_nil @described_class.user_id_for(Authentication::Identifier.email('someone@notthere.com'))
  end

  test 'user_id_for when present' do
    @record.save!
    assert_equal @user_id, @described_class.user_id_for(@identifier)
  end
end
