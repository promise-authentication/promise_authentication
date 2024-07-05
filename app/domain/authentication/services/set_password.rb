class Authentication::Services::SetPassword
  include ActiveModel::Model

  attr_accessor :user_id, :password, :personal_data, :password_known_by_relying_party_id
  attr_reader :vault_key

  def call
    raise 'Already called' if vault_key

    digest = Authentication::Password.digest_from(password)

    vault_key_salt = Authentication::Vault.generate_salt
    vault_key = Authentication::Vault.key_from(password, vault_key_salt)

    vault_key_cipher, key_pair_id = Authentication::Services::EncryptVaultKey.call(vault_key, user_id)

    Authentication::Commands::AddPassword.new(
      user_id: user_id,
      vault_key_salt: vault_key_salt,
      digest: digest,
      encrypted_vault_key: {
        cipher_base64: vault_key_cipher,
        key_pair_id: key_pair_id
      },
      password_known_by_relying_party_id: password_known_by_relying_party_id
    ).execute!

    cipher = Authentication::Vault.new(key: vault_key).encrypt(personal_data)

    Authentication::Commands::UpdateVault.new(
      user_id: user_id,
      encrypted_personal_data: cipher
    ).execute!

    @vault_key = vault_key
  end
end
