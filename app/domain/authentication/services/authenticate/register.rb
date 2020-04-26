module Authentication::Services::Authenticate::Register
  module_function

  def call(email:, password:, relying_party_id: nil, legacy_account_user_id: nil, relying_party_knows_password: false)
    new_user_id = SecureRandom.uuid

    hashed_email = Authentication::HashedEmail.from_cleartext(email)

    thing = Authentication::Commands::ClaimEmail.new(
      user_id: new_user_id,
      hashed_email: hashed_email
    ).execute!

    data = Authentication::PersonalData.new
    if(relying_party_id.present? && legacy_account_user_id.present?)
      data.add_id legacy_account_user_id, relying_party_id
    end

    vault_key = Authentication::Services::SetPassword.new(
      user_id: new_user_id,
      password: password,
      personal_data: data,
      password_known_by_relying_party_id: relying_party_knows_password ? relying_party_id : nil
    ).call

    return new_user_id, vault_key
  end

end
