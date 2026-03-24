module Authentication::Services::Authenticate::Register
  module_function

  def call(email:, password:, relying_party_id: nil, legacy_account_user_id: nil, relying_party_knows_password: false, email_verified_at: nil)
    new_user_id = SecureRandom.uuid

    hashed_email = Authentication::HashedEmail.from_cleartext(email)

    vault_key = nil

    ActiveRecord::Base.transaction do
      Authentication::Commands::ClaimEmail.new(
        user_id: new_user_id,
        hashed_email: hashed_email,
        email_verified_at: email_verified_at
      ).execute!

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
end
