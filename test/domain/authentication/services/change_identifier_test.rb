require 'test_helper'

class Authentication::Services::ChangeIdentifierTest < ActiveSupport::TestCase
  setup do
    @password = 'secret'
    @from = Authentication::Identifier.email('hello@world.dk')
    @to = Authentication::Identifier.phone('+4520123456')

    auth = Authentication::Services::Authenticate.new(email: @from.value, password: @password)
    auth.register!
    @user_id = auth.user_id

    Authentication::Services::PrepareIdentifierForValidation.new(identifier: @to).generate_and_send_verification_code!
    @code = VerificationCode.find_for(@to)
  end

  test 'switches the claimed identifier from e-mail to phone' do
    request = Authentication::Services::ChangeIdentifier.new(
      user_id: @user_id,
      confirmation_code: @code.code,
      from_identifier: @from,
      to_identifier: @to
    )

    assert request.valid?, request.errors.full_messages
    assert request.call

    # The phone is now the claimed identifier
    assert_equal @user_id, Authentication::HashedIdentifier.user_id_for(@to)
    assert_nil Authentication::HashedIdentifier.user_id_for(@from)

    record = Authentication::HashedIdentifier.find_by(user_id: @user_id)
    assert_equal 'phone', record.identifier_type
    assert_equal 1, Authentication::HashedIdentifier.where(user_id: @user_id).count
  end

  test 'fails with a wrong code' do
    request = Authentication::Services::ChangeIdentifier.new(
      user_id: @user_id,
      confirmation_code: 'wrong',
      from_identifier: @from,
      to_identifier: @to
    )

    refute request.call
    assert request.errors[:confirmation_code].present?
    assert_equal @user_id, Authentication::HashedIdentifier.user_id_for(@from)
  end
end
