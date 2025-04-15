# This class should only be used for claimed and verified
# emails.

class Authentication::HashedEmail < ApplicationRecord
  validates :user_id, presence: true

  def self.from_cleartext(email)
    return nil if email.nil?

    # Double hashing:
    # To avoid collisions, the assumption is, that if we
    # are unlucky enough to get a collision in one algorithm,
    # we should not be so unlucky that it also collides in the other...
    # I'm sure, though, that I will be proven wrong at some point. ~AL
    # 20250415: That was a stupid assumption. If we get a collision in SHA256,
    # that collision will carry over to BLAKE2b as well. That is the whole idea
    # of hashing. Same string, same hash. Sorry. ~AL
    sha = RbNaCl::Hash.sha256(email)
    blake = RbNaCl::Hash.blake2b(email)
    binary = sha + blake

    Base64.strict_encode64(binary).encode('utf-8')
  end

  def self.user_id_for_cleartext(email)
    id = from_cleartext(email)

    find(id).user_id
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
