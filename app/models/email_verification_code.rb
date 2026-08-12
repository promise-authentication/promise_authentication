class EmailVerificationCode < ApplicationRecord
  # Codes and magic links share this lifetime, so the whole verification
  # mail expires at once — never a dead link next to a working code.
  TTL = 1.hour

  module HumanReadableCode
    ALPHABET = 'abcdefghkmnpqrstuvwxyz23456789'.freeze
    def self.generate(range)
      # The length should be a random number in the range
      length = range.to_a.sample(1, random: SecureRandom).first
      # The code should be a random string of the given length
      # sampled from the alphabet
      Array.new(length) { ALPHABET.chars.sample(1, random: SecureRandom).first }.join
    end
  end

  def self.find_by_cleartext(email)
    hashed = Authentication::HashedEmail.from_cleartext(email)

    find(hashed)
  rescue ActiveRecord::RecordNotFound
    return nil
  end

  # Like find_by_cleartext, but treats expired codes as absent.
  # Use this everywhere a code is checked or displayed; the raw
  # find_by_cleartext remains for cleanup.
  def self.active_for_cleartext(email)
    code = find_by_cleartext(email)
    return nil if code.nil? || code.expired?

    code
  end

  def self.sweep_expired!
    where('created_at < ?', TTL.ago).delete_all
  end

  def expired?
    created_at < TTL.ago
  end
end
