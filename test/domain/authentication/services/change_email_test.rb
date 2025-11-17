require 'test_helper'

class Authentication::Services::ChangeEmailTest < ActiveSupport::TestCase
  setup do
    @old_password = 'secret'
    @old_email = 'hello@world.dk'
    @authentication = Authentication::Services::Authenticate.new(
      email: @old_email,
      password: @old_password
    )
    @authentication.register!
    assert @authentication.user_id
    @user_id = @authentication.user_id

    @new_email = 'new@world.dk'
    @hashed_email = Authentication::HashedEmail.from_cleartext(@new_email)

    Authentication::Services::PrepareEmailForValidation.new(
      email: @new_email
    ).generate_and_send_verification_code!

    @code = EmailVerificationCode.find_by_cleartext(@new_email)

    @request = Authentication::Services::ChangeEmail.new(
      user_id: @user_id,
      confirmation_code: @code.code,
      from_email: @old_email,
      to_email: @new_email
    )
  end

  test 'is should be valid' do
    assert @request.valid?, @request.errors.full_messages
  end

  test 'it fails if already claimed' do
    Authentication::Services::Authenticate.new(
      email: @new_email,
      password: @old_password
    ).register!

    assert_raise Authentication::Email::AlreadyClaimed do
      @request.call
    end

    # And you can not claim the old one (i.e. it was not unclaimed)
    assert_nil Rails.configuration.event_store.read.of_type(Authentication::Events::EmailUnclaimed).last
    assert_raise Authentication::Email::AlreadyClaimed do
      Authentication::Commands::ClaimEmail.new(
        hashed_email: Authentication::HashedEmail.from_cleartext(@old_email),
        user_id: 'whatever',
        email_verified_at: Time.zone.now
      ).execute!
    end
  end

  test 'it works if the email is not already claimed' do
    @request.call

    # Events
    claim_event = Rails.configuration.event_store.read.of_type(Authentication::Events::EmailClaimed).last
    unclaim_event = Rails.configuration.event_store.read.of_type(Authentication::Events::EmailUnclaimed).last

    assert_equal claim_event.data[:user_id], @user_id
    assert_equal claim_event.data[:hashed_email], @hashed_email

    assert_equal unclaim_event.data[:user_id], @user_id
    assert_equal unclaim_event.data[:hashed_email], Authentication::HashedEmail.from_cleartext(@old_email)

    # Read models
    hashed = Authentication::HashedEmail.find_by_user_id(@user_id)
    assert hashed
    assert_equal hashed.id, @hashed_email

    assert Authentication::HashedEmail.count == 1

    # And you can claim the old one again
    Authentication::Commands::ClaimEmail.new(
      hashed_email: Authentication::HashedEmail.from_cleartext(@old_email),
      user_id: 'whatever',
      email_verified_at: Time.zone.now
    ).execute!
    claim_event = Rails.configuration.event_store.read.of_type(Authentication::Events::EmailClaimed).last
    assert_equal claim_event.data[:user_id], 'whatever'
  end
end
