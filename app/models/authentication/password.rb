class Authentication::Password < ApplicationRecord

  class NotMatching < StandardError ; end

  def self.digest_from(password)
    RbNaCl::PasswordHash.argon2_str(password)
  end

  def match!(cleartext_password)
    raise NotMatching unless RbNaCl::PasswordHash.argon2_valid?(cleartext_password, digest)
    return true
  end

end
