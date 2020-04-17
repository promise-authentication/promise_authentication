module Authentication::Services::Authenticate::Register
  module_function

  def call(email, password)
    new_user_id = SecureRandom.uuid

    hashed_email = Authentication::HashedEmail.from_cleartext(email)

    thing = Authentication::Commands::ClaimEmail.new(
      user_id: new_user_id,
      hashed_email: hashed_email
    ).execute!

    data = Authentication::PersonalData.new
    data.add_email email

    vault_key = Authentication::Services::SetPassword.new(
      user_id: new_user_id,
      password: password,
      personal_data: data
    ).call

    return new_user_id, vault_key
  end

end
