# A user-facing login identifier. Today that is either an e-mail address
# or a telephone number. The identifier is never stored in the clear; only
# its #digest (a deterministic hash) is used as a lookup key, exactly like
# Authentication::HashedEmail did historically for e-mails.
#
# This value object centralises normalisation (so the same human input
# always produces the same digest) and validation for every identifier type.
class Authentication::Identifier
  TYPES = %i[email phone].freeze

  class InvalidType < StandardError; end

  attr_reader :type, :value

  def self.email(value)
    new(type: :email, value: value)
  end

  def self.phone(value)
    new(type: :phone, value: value)
  end

  # Build from raw user input plus the type chosen in the UI.
  def self.parse(raw, type:)
    new(type: type, value: raw)
  end

  def initialize(type:, value:)
    @type = type&.to_sym
    raise InvalidType, @type.inspect unless TYPES.include?(@type)

    @value = normalize(value)
  end

  def email?
    type == :email
  end

  def phone?
    type == :phone
  end

  def valid?
    return false if value.blank?

    case type
    when :email then EmailInquire.validate(value).valid?
    when :phone then Phonelib.valid?(value)
    end
  end

  # What we show back to the user (normalised e-mail / E.164 number).
  def display_value
    value
  end

  # The deterministic lookup key stored in authentication_hashed_identifiers
  # and used as the aggregate id of the claim event stream.
  def digest
    self.class.digest(value)
  end

  def ==(other)
    other.is_a?(self.class) && other.type == type && other.value == value
  end
  alias eql? ==

  def hash
    [type, value].hash
  end

  # Double hashing (SHA256 + BLAKE2b) kept identical to the historical
  # Authentication::HashedEmail implementation so existing e-mail digests
  # stay stable across this refactor.
  def self.digest(cleartext)
    return nil if cleartext.nil?

    sha = RbNaCl::Hash.sha256(cleartext)
    blake = RbNaCl::Hash.blake2b(cleartext)
    Base64.strict_encode64(sha + blake).encode('utf-8')
  end

  private

  def normalize(raw)
    return nil if raw.nil?

    case type
    when :email
      raw.strip.downcase
    when :phone
      parsed = Phonelib.parse(raw)
      parsed.valid? ? parsed.e164 : raw.strip
    end
  end
end
