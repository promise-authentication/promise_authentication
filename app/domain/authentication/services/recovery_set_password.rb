class Authentication::Services::RecoverySetPassword
  include ActiveModel::Model

  attr_accessor :user_id, :new_password, :secret_key_base64
  attr_reader :vault_key

  def call!
    recovery = Authentication::VaultKeysForRecovery.find(user_id)
    old_vault_key = recovery.recovered_vault_key(secret_key_base64)

    personal_data = Authentication::Vault.personal_data!(user_id, old_vault_key)

    Authentication::Services::SetPassword.new(
      password: new_password,
      user_id: user_id,
      personal_data: personal_data
    ).call
  end
end
