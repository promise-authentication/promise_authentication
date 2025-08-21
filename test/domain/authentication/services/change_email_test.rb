require 'test_helper'

class Authentication::Services::ChangePasswordTest < ActiveSupport::TestCase
  setup do
    @old_password = 'secret'
    @authentication = Authentication::Services::Authenticate.new(
      email: 'hello@world.dk',
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
      new_email: @new_email
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
  end

  test 'it works if the email is not already claimed' do
    @request.call
    hashed = Authentication::HashedEmail.find_by_user_id(@user_id)
    assert hashed
    assert_equal hashed.id, @hashed_email
  end
end
