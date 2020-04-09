module Authentication::Services::GetIdToken::Register
  module_function

  def call(user_id, relying_party_id, vault_key)
    new_id = nil

    with_retries :rescue => Authentication::Identity::AlreadyClaimed do
      new_id = SecureRandom.uuid
      Authentication::Commands::ClaimIdentity.new(
        id: new_id,
        relying_party_id: relying_party_id
      ).execute!
    end

    personal_data = Authentication::Vault.personal_data(user_id, vault_key)
    personal_data.add_id new_id, relying_party_id

    cipher = Authentication::Vault.new(key: vault_key).encrypt(personal_data)

    Authentication::Commands::UpdateVault.new(
      user_id: user_id,
      encrypted_personal_data: cipher
    ).execute!

    new_id
  end
end
