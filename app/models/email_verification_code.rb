# Backwards-compatible shim for the e-mail-specific lookup. Shares the
# verification_codes table with its parent. New code should use
# VerificationCode.find_for(identifier).
class EmailVerificationCode < VerificationCode
  def self.find_by_cleartext(email)
    find_for(Authentication::Identifier.email(email))
  end
end
