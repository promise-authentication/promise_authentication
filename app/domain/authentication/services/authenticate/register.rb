module Authentication::Services::Authenticate::Register
  module_function

  def call(identifier:, password:, relying_party_id: nil, legacy_account_user_id: nil, relying_party_knows_password: false, verified_at: nil)
    new_user_id = SecureRandom.uuid

    vault_key = nil

    ActiveRecord::Base.transaction do
      claim_identifier(identifier, new_user_id, verified_at)

      data = Authentication::PersonalData.new
      if relying_party_id.present? && legacy_account_user_id.present?
        data.add_id legacy_account_user_id, relying_party_id
      end

      Authentication::Commands::AddSomethingUnique.new(
        user_id: new_user_id,
        something_unique: Authentication::SomethingUnique.generate
      ).execute!

      vault_key = Authentication::Services::SetPassword.new(
        user_id: new_user_id,
        password: password,
        personal_data: data,
        password_known_by_relying_party_id: relying_party_knows_password ? relying_party_id : nil
      ).call
    end

    [new_user_id, vault_key]
  end

  def claim_identifier(identifier, user_id, verified_at)
    if identifier.phone?
      Authentication::Commands::ClaimPhone.new(
        user_id: user_id,
        hashed_phone: identifier.digest,
        phone_verified_at: verified_at
      ).execute!
    else
      Authentication::Commands::ClaimEmail.new(
        user_id: user_id,
        hashed_email: identifier.digest,
        email_verified_at: verified_at
      ).execute!
    end
  end
end
