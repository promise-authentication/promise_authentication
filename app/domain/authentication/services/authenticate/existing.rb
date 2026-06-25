module Authentication::Services::Authenticate::Existing
  module_function

  # Accepts an Authentication::Identifier or, for backwards compatibility,
  # a cleartext e-mail string.
  def known?(identifier)
    !!Authentication::HashedIdentifier.user_id_for(coerce(identifier))
  end

  def call(identifier, password)
    current_user_id = Authentication::HashedIdentifier.user_id_for(coerce(identifier))

    return nil unless current_user_id.present?

    pw = Authentication::Password.find(current_user_id)

    pw.match!(password)

    vault_key = Authentication::Vault.key_from(password, pw.vault_key_salt)

    [current_user_id, vault_key]
  end

  def coerce(identifier)
    return identifier if identifier.is_a?(Authentication::Identifier)

    Authentication::Identifier.email(identifier)
  end
end
