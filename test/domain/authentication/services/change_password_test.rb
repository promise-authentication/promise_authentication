require 'test_helper'

class Authentication::Services::ChangePasswordTest < ActiveSupport::TestCase
  setup do
    @old_password = 'secret'
    @authentication = Authentication::Services::Authenticate.new(
      email: 'hello@world.dk',
      password: @old_password
    )
    @user_id, @salt = @authentication.user_id_and_salt

    @new_password = 'verysecret'

    @request = Authentication::Services::ChangePassword.new(
      current_password: @old_password,
      new_password: @new_password,
      user_id: @user_id
    )
  end

  test 'is should be valid' do
    assert @request.valid?
  end

  test 'it fails if not knowing current vault' do
    @request.current_password = 'hello'
    assert_raise Authentication::Password::NotMatching do
      @request.new_salt
    end
  end

  test 'it should provide new salt and set password' do
    new_salt = @request.new_salt
    assert new_salt

    key = Authentication::Vault.key_from(@new_password, new_salt)
    personal_data = Authentication::Vault.personal_data(@user_id, key)
    assert personal_data

    hashed = Authentication::Password.find(@user_id)
    assert hashed.match!(@new_password)
  end
end
