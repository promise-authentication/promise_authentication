class Authentication::HashedEmail < ApplicationRecord
  validates :user_id, presence: true

  def self.from_cleartext(email)
    return nil if email.nil?

    # Double hashing:
    # To avoid collisions, the assumption is, that if we
    # are unlucky enough to get a collision in one algorithm,
    # we should not be so unlucky that it also collides in the other...
    # I'm sure, though, that I will be proven wrong at some point.
    sha = RbNaCl::Hash.sha256(email)
    blake = RbNaCl::Hash.blake2b(email)
    binary = sha + blake

    # Now get the hexdigest of
    binary.unpack('H*').first.encode('utf-8')
  end

  def self.user_id_for_cleartext(email)
    id = from_cleartext(email)

    find(id).user_id
  rescue ActiveRecord::RecordNotFound
    return nil
  end
end
