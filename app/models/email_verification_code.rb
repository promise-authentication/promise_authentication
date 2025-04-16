class EmailVerificationCode < ApplicationRecord
  module HumanReadableCode
    ALPHABET = 'ABCDEFGHKMNPQRSTUVWXYZ23456789'.freeze
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
  end
end
