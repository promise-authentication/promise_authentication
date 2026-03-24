# This class should only be used for claimed and verified
# emails.

class Authentication::HashedEmail < ApplicationRecord
  validates :user_id, presence: true

  def self.from_cleartext(email)
    return nil if email.nil?
    clean_email = email.strip.downcase

    # Double hashing:
    # To avoid collisions, the assumption is, that if we
    # are unlucky enough to get a collision in one algorithm,
    # we should not be so unlucky that it also collides in the other...
    # I'm sure, though, that I will be proven wrong at some point. ~AL
    # 20250415: That was a stupid assumption. If we get a collision in SHA256,
    # that collision will carry over to BLAKE2b as well. That is the whole idea
    # of hashing. Same string, same hash. Sorry. ~AL
    # 20250415: Well, maybe not THAT stupid. The way we do it here, actually
    # makes it less likely to get a collision. We do not, as I previously
    # thought, base one hash on the other. We should be good. ~AL
    sha = RbNaCl::Hash.sha256(clean_email)
    blake = RbNaCl::Hash.blake2b(clean_email)
    binary = sha + blake

    Base64.strict_encode64(binary).encode('utf-8')
  end

  def self.find_by_cleartext(email)
    id = from_cleartext(email)

    find_by(id: id)
  end

  def self.user_id_for_cleartext(email)
    id = from_cleartext(email)

    find(id).user_id
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
