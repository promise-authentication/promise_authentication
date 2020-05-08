class AboutController < ApplicationController
  def welcome
  end

  def open
  end

  def data
    @email = 'test@example.com'
    @password = ENV.fetch('PROMISE_PASSWORD_FOR_TEST_USER') { 'secret' }
    @auth = Authentication::Services::Authenticate.new(
      email: @email,
      password: @password,
      relying_party_id: 'example.com'
    )
    @auth.call!

    @id_token = Authentication::Services::GetIdToken.new(
      user_id: @auth.user_id, 
      relying_party_id: 'example.com',
      vault_key: @auth.vault_key,
    ).id_token

    @personal_data = Authentication::Vault.personal_data(@auth.user_id, @auth.vault_key)

    @vault_content = Authentication::VaultContent.find(@auth.user_id)

    @vault_key_for_recovery = Authentication::VaultKeysForRecovery.find(@auth.user_id)
  end
end
