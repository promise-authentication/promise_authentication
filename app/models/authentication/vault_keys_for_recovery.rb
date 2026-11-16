class Authentication::VaultKeysForRecovery < ApplicationRecord
  def info
    uniq_key_pair = Authentication::KeyPair.find(key_pair_id)

    return {
      public_key_base64: uniq_key_pair.public_key_base64,
      vault_key_cipher_base64: vault_key_cipher_base64
    }
  end
end
