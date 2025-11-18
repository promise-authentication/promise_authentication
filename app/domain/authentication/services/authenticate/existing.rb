module Authentication::Services::Authenticate::Existing
  module_function

  def known?(cleartext_email)
    !!Authentication::HashedEmail.user_id_for_cleartext(cleartext_email)
  end

  def call(email, password)
    current_user_id = Authentication::HashedEmail.user_id_for_cleartext(email)

    return nil unless current_user_id.present?

    pw = Authentication::Password.find(current_user_id)

    pw.match!(password)

    vault_key = Authentication::Vault.key_from(password, pw.vault_key_salt)

    [current_user_id, vault_key]
  end
end
