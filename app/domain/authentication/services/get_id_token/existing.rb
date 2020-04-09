module Authentication::Services::GetIdToken::Existing
  module_function

  def call(user_id, relying_party_id, vault_key)
    personal_data = Authentication::Vault.personal_data(user_id, vault_key)

    personal_data.id_for(relying_party_id)
  end
end
