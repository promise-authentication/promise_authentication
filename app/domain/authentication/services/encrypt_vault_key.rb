module Authentication::Services::EncryptVaultKey
  module_function

  def call(vault_key, user_id)
    key = Trust::KeyPair.create
    off_site_public_key = Base64.strict_decode64 key.public_key

    uniq_private_key = RbNaCl::PrivateKey.generate
    uniq_public_key = uniq_private_key.public_key

    box = RbNaCl::SimpleBox.from_keypair(
      off_site_public_key,
      uniq_private_key
    )

    vault_key_cipher = box.encrypt(vault_key)

    key_pair_id = SecureRandom.uuid
    Authentication::KeyPair.create!(
      id: key_pair_id,
      user_id: user_id,
      public_key_base64: Base64.strict_encode64(uniq_public_key),
      off_site_public_key_base64: key.public_key
    )

    return Base64.strict_encode64(vault_key_cipher).encode('utf-8'),
      key_pair_id
  end
end

