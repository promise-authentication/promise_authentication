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
    @vault_key = @authentication.vault_key

    @new_password = 'verysecret'

    @request = Authentication::Services::ChangePassword.new(
      current_password: @old_password,
      new_password: @new_password,
      user_id: @user_id
    )
  end

  test 'is should be valid' do
    assert @request.valid?, @request.errors.full_messages
  end

  test 'it fails if not knowing current vault' do
    @request.current_password = 'hello'
    assert_raise Authentication::Password::NotMatching do
      @request.call
    end
  end

  test 'it should provide new salt and set password' do
    @request.call
    new_vault_key = @request.new_vault_key
    assert new_vault_key

    personal_data = Authentication::Vault.personal_data(@user_id, new_vault_key)
    assert personal_data

    hashed = Authentication::Password.find(@user_id)
    assert hashed.match!(@new_password)
  end
end
