class Authentication::Events::PasswordSet < DomainEvent
  def recover_info
    uniq_key_pair = Authentication::KeyPair.find(data[:encrypted_vault_key][:key_pair_id])

    return {
      private_key_cipher: uniq_key_pair.private_key_cipher_base64,
      vault_key_cipher: data[:encrypted_vault_key][:cipher_base64]
    }
  end
end
