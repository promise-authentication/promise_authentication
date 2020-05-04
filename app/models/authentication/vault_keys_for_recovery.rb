class Authentication::VaultKeysForRecovery < ApplicationRecord
  def info
    uniq_key_pair = Authentication::KeyPair.find(key_pair_id)

    return {
      public_key_base64: uniq_key_pair.public_key_base64,
      vault_key_cipher_base64: vault_key_cipher_base64
    }
  end

  def recovered_vault_key(secret_key_base64)
    key = Base64.strict_decode64(secret_key_base64)
    box = RbNaCl::SimpleBox.from_secret_key(key)
    box.decrypt(Base64.strict_decode64(recoverable_vault_key_cipher_base64))
  end
end
