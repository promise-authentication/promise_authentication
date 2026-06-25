# Backwards-compatible e-mail-specific wrapper around
# PrepareIdentifierForValidation. Existing callers construct this with an
# `email:` string; new code should build an Authentication::Identifier and use
# PrepareIdentifierForValidation directly.
class Authentication::Services::PrepareEmailForValidation < Authentication::Services::PrepareIdentifierForValidation
  attr_accessor :email

  def identifier
    Authentication::Identifier.email(email)
  end
end
