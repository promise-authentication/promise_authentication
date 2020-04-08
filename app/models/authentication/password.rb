class Authentication::Password < ApplicationRecord

  def self.digest_from(password)
    RbNaCl::PasswordHash.argon2_str(password)
  end

  def match!(cleartext_password)
    RbNaCl::PasswordHash.argon2_valid?(cleartext_password, digest)
  end

end
