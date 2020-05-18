class Authentication::Services::RecoverySetPassword
  include ActiveModel::Model

  attr_accessor :new_password, :token
  attr_reader :vault_key

  def call!
    recovery_token = Authentication::RecoveryToken.find_by_token(token)
    user_id = recovery_token.user_id

    recovery = Authentication::VaultKeysForRecovery.find(user_id)
    key_pair = Authentication::KeyPair.find(recovery.key_pair_id)

    off_site_key = Trust::KeyPair.find(key_pair.off_site_public_key_base64)
    private_key = Base64.strict_decode64(off_site_key.private_key)

    box = RbNaCl::SimpleBox.from_keypair(
      Base64.strict_decode64(key_pair.public_key_base64),
      private_key
    )
    old_vault_key = box.decrypt(Base64.strict_decode64(recovery.vault_key_cipher_base64))

    personal_data = Authentication::Vault.personal_data!(user_id, old_vault_key)

    Authentication::Services::SetPassword.new(
      password: new_password,
      user_id: user_id,
      personal_data: personal_data
    ).call

    recovery_token.destroy
  end
end
