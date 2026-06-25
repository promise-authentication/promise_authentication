# Backwards-compatible shim around Authentication::HashedIdentifier for the
# e-mail-specific call sites (admin legacy-account flow, public stats, the
# existing authentication services). New code should prefer
# Authentication::Identifier + Authentication::HashedIdentifier directly.
class Authentication::HashedEmail
  def self.from_cleartext(email)
    return nil if email.nil?

    Authentication::Identifier.email(email).digest
  end

  def self.find_by_cleartext(email)
    Authentication::HashedIdentifier.find_by(id: from_cleartext(email))
  end

  def self.user_id_for_cleartext(email)
    Authentication::HashedIdentifier.user_id_for(Authentication::Identifier.email(email))
  end

  def self.find_by_user_id(user_id)
    Authentication::HashedIdentifier.find_by(user_id: user_id, identifier_type: 'email')
  end

  def self.count
    Authentication::HashedIdentifier.where(identifier_type: 'email').count
  end
end
