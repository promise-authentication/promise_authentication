module Authentication::Services::Authenticate::Register
  module_function

  def call(email, password)
    new_user_id = SecureRandom.uuid

    hashed_email = Authentication::HashedEmail.from_cleartext(email)

    thing = Authentication::Commands::ClaimEmail.new(
      user_id: new_user_id,
      hashed_email: hashed_email
    ).execute!

    vault_key_salt = SecureRandom.uuid
    digest = Authentication::Password.digest_from(password)

    Authentication::Commands::AddPassword.new(
      user_id: new_user_id,
      vault_key_salt: vault_key_salt,
      digest: digest
    ).execute!

    data = Authentication::PersonalData.new
    data.add_email email
    vault_key = Authentication::Vault.key_from(password, vault_key_salt)
    cipher = Authentication::Vault.new(key: vault_key).encrypt(data)

    Authentication::Commands::UpdateVault.new(
      user_id: new_user_id,
      encrypted_personal_data: cipher
    ).execute!

    return new_user_id, vault_key_salt
  end

end
