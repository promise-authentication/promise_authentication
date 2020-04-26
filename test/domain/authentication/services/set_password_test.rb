require 'test_helper'

class Authentication::Services::SetPasswordTest < ActiveSupport::TestCase
  setup do
    @user_id = 'uid'
    @password = 'secret'
    @email = 'hello@example.com'
    @personal_data = Authentication::PersonalData.new

    @request = Authentication::Services::SetPassword.new(
      user_id: @user_id,
      password: @password,
      personal_data: @personal_data
    )
  end

  test 'sets everything' do
    Authentication::Services::VaultKeyEncrypter.stub :call, ['cipher', 'key_pair_id'] do
      key = @request.call
      assert key
      assert_equal key.encoding, Encoding::UTF_8

      event = Rails.configuration.event_store.read.of_type(Authentication::Events::PasswordSet).last
      assert event
      assert_equal event.data[:encrypted_vault_key][:cipher_base64], 'cipher'
      assert_equal event.data[:encrypted_vault_key][:key_pair_id], 'key_pair_id'
      assert event.data[:vault_key_salt]
      assert event.data[:digest]
      assert_equal event.data[:user_id], @user_id
      assert_nil event.data[:password_known_by_relying_party_id]
    end
  end
end
