class Authentication::Services::SetPassword
  include ActiveModel::Model

  attr_accessor :user_id, :password, :personal_data
  attr_reader :vault_key

  def call
    raise 'Already called' if vault_key

    vault_key_salt = SecureRandom.uuid
    digest = Authentication::Password.digest_from(password)

    vault_key = Authentication::Vault.key_from(password, vault_key_salt)

    # Encrypt vault key with public key encryption
    box = RbNaCl::SimpleBox.from_keypair(
      Base64.strict_decode64(ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION']),
      Base64.strict_decode64(ENV['PROMISE_PRIVATE_KEY_FOR_VAULT_KEY_ENCRYPTION'])
    )

    Authentication::Commands::AddPassword.new(
      user_id: user_id,
      vault_key_salt: vault_key_salt,
      digest: digest,
      encrypted_vault_key: Base64.strict_encode64(box.encrypt(vault_key)).encode('utf-8')
    ).execute!

    cipher = Authentication::Vault.new(key: vault_key).encrypt(personal_data)

    Authentication::Commands::UpdateVault.new(
      user_id: user_id,
      encrypted_personal_data: cipher
    ).execute!

    @vault_key = vault_key
  end
end
