module Authentication::Services::Authenticate::Existing
  module_function

  def call(email, password)
    current_user_id = Authentication::HashedEmail.user_id_for_cleartext(email)

    return nil unless current_user_id.present?

    pw = Authentication::Password.find(current_user_id)

    pw.match!(password)

    return current_user_id, pw.vault_key_salt
  end
end
