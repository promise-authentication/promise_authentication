class Authentication::Events::PasswordSet < DomainEvent
  def recover_info
    uniq_key_pair = Authentication::KeyPair.find(data[:encrypted_vault_key][:key_pair_id])

    return {
      public_key_base64: uniq_key_pair.public_key_base64,
      vault_key_cipher: data[:encrypted_vault_key][:cipher_base64]
    }
  end
end
