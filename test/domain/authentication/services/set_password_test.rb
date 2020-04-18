require 'test_helper'

class Authentication::Services::SetPasswordTest < ActiveSupport::TestCase
  setup do
    @user_id = 'uid'
    @password = 'secret'
    @email = 'hello@example.com'
    @personal_data = Authentication::PersonalData.new
    @personal_data.add_email @email

    @request = Authentication::Services::SetPassword.new(
      user_id: @user_id,
      password: @password,
      personal_data: @personal_data
    )

    @private_key = RbNaCl::PrivateKey.generate
    @public_key = @private_key.public_key
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.encode64(@public_key.to_s).encode('utf-8')

    own_private = RbNaCl::PrivateKey.generate
    @own_public = own_private.public_key.to_s

    ENV['PROMISE_PRIVATE_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.encode64(own_private.to_s).encode('utf-8')
  end

  test 'keys are utf-8' do
    assert_equal ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'].encoding, Encoding::UTF_8
    assert_equal ENV['PROMISE_PRIVATE_KEY_FOR_VAULT_KEY_ENCRYPTION'].encoding, Encoding::UTF_8
  end

  test 'sets everything' do
    key = @request.call
    assert key

    event = Rails.configuration.event_store.read.of_type(Authentication::Events::PasswordSet).last
    assert event
    assert_equal event.data[:encrypted_vault_key].encoding, Encoding::UTF_8
    assert event.data[:vault_key_salt]
    assert event.data[:digest]
    assert_equal event.data[:user_id], @user_id

    box = RbNaCl::SimpleBox.from_keypair(
      @own_public,
      @private_key.to_s
    )
    plaintext = box.decrypt(Base64.decode64(event.data[:encrypted_vault_key]))
    assert_equal plaintext, key
  end
end
