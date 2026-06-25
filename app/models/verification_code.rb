# A short, human-readable, single-use code sent to an identifier (e-mail or
# phone) to prove ownership. Keyed by the identifier #digest.
class VerificationCode < ApplicationRecord
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

  def self.find_for(identifier)
    find(identifier.digest)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
