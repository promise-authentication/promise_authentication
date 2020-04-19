module Authentication::Services::VaultKeyEncrypter
  module_function

  def call(vault_key)

    on_site_private_key_for_encryption =
      Base64.strict_decode64(ENV['PROMISE_PRIVATE_KEY_FOR_VAULT_KEY_ENCRYPTION']) 

    off_site_public_key_for_encryption_of_uniq_private_key =
      Base64.strict_decode64(ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'])

    uniq_private_key_for_decryption_of_vault_key = RbNaCl::PrivateKey.generate

    uniq_public_key_for_encryption_of_vault_key =
      uniq_private_key_for_decryption_of_vault_key.public_key

    saved_uniq_public_key_used_for_encryption_of_vault_key = Base64.strict_encode64(
      uniq_public_key_for_encryption_of_vault_key
    )

    box_for_vault_key = RbNaCl::SimpleBox.from_keypair(
      uniq_public_key_for_encryption_of_vault_key,
      on_site_private_key_for_encryption
    )
    box_for_private_key = RbNaCl::SimpleBox.from_keypair(
      off_site_public_key_for_encryption_of_uniq_private_key,
      on_site_private_key_for_encryption
    )

    private_key_cipher =
      box_for_private_key.encrypt(uniq_private_key_for_decryption_of_vault_key)
    vault_key_cipher =
      box_for_vault_key.encrypt(vault_key)

    saved_uniq_public_key_used_for_encryption = Base64.strict_encode64(uniq_private_key_for_decryption_of_vault_key).encode('utf-8')


    Authentication::KeyPair.create!(
      id: saved_uniq_public_key_used_for_encryption,
      private_key_cipher_base64: Base64.strict_encode64(private_key_cipher)
    )

    return Base64.strict_encode64(vault_key_cipher).encode('utf-8'),
      saved_uniq_public_key_used_for_encryption
  end
end

