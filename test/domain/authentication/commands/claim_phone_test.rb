require 'test_helper'

class Authentication::Commands::ClaimPhoneTest < ActiveSupport::TestCase
  setup do
    @identifier = Authentication::Identifier.phone('+4520123456')
    @hashed_phone = @identifier.digest
    @user_id = SecureRandom.uuid
  end

  test 'claiming a phone projects a phone-typed hashed identifier' do
    verified_at = Time.zone.now

    Authentication::Commands::ClaimPhone.new(
      hashed_phone: @hashed_phone,
      user_id: @user_id,
      phone_verified_at: verified_at
    ).execute!

    record = Authentication::HashedIdentifier.find(@hashed_phone)
    assert_equal @user_id, record.user_id
    assert_equal 'phone', record.identifier_type
    assert record.verified_at
    assert_equal @user_id, Authentication::HashedIdentifier.user_id_for(@identifier)
  end

  test 'claiming the same phone twice raises' do
    Authentication::Commands::ClaimPhone.new(
      hashed_phone: @hashed_phone, user_id: @user_id
    ).execute!

    assert_raises Authentication::Phone::AlreadyClaimed do
      Authentication::Commands::ClaimPhone.new(
        hashed_phone: @hashed_phone, user_id: SecureRandom.uuid
      ).execute!
    end
  end

  test 'requires a hashed phone' do
    refute Authentication::Commands::ClaimPhone.new(user_id: @user_id).valid?
  end
end
