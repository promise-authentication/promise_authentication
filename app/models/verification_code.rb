# A short, human-readable, single-use code sent to an identifier (e-mail or
# phone) to prove ownership. Keyed by the identifier #digest.
class VerificationCode < ApplicationRecord
  # A code is only valid for a short window after it is issued.
  EXPIRES_AFTER = 15.minutes
  # Wrong guesses allowed before the code is burned and must be re-requested.
  # This bounds online brute-force of the (short) code to a handful of tries.
  MAX_ATTEMPTS = 5

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

  # Returns the live code for an identifier, or nil. Expired codes are treated
  # as absent and cleaned up, so callers never see a stale code.
  def self.find_for(identifier)
    code = find_by(id: identifier.digest)
    return nil if code.nil?

    if code.expired?
      code.destroy
      return nil
    end

    code
  end

  def expired?
    created_at < EXPIRES_AFTER.ago
  end

  # Verifies a user-supplied code. Returns true on a match. A wrong guess is
  # counted, and once MAX_ATTEMPTS is reached the code is burned, forcing the
  # user to request a fresh one. Expired or blank input never matches.
  def verify(input)
    return false if input.blank? || expired?

    return true if code.casecmp?(input.to_s.strip)

    register_failed_attempt!
    false
  end

  private

  def register_failed_attempt!
    increment!(:attempts)
    destroy if attempts >= MAX_ATTEMPTS
  end
end
