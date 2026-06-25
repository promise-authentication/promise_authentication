# Changes the identifier (e-mail or phone) a user signs in with. The user
# proves ownership of the new identifier with a verification code (sent by
# e-mail or SMS). The new identifier is claimed, then the old one unclaimed.
class Authentication::Services::ChangeIdentifier
  include ActiveModel::Model

  attr_accessor :user_id, :confirmation_code, :from_identifier, :to_identifier

  validates :user_id, :confirmation_code, :from_identifier, :to_identifier, presence: true

  def call
    verifier = Authentication::Services::PrepareIdentifierForValidation.new(identifier: to_identifier)

    unless verifier.verify!(confirmation_code)
      errors.add(:confirmation_code, 'is invalid')
      return false
    end

    # First claim the new one
    claim(to_identifier)
    # Then unclaim the old one
    unclaim(from_identifier)

    # Reset the verification code after a successful change
    verifier.reset!

    true
  end

  private

  def claim(identifier)
    if identifier.phone?
      Authentication::Commands::ClaimPhone.new(
        hashed_phone: identifier.digest,
        user_id: user_id,
        phone_verified_at: Time.zone.now
      ).execute!
    else
      Authentication::Commands::ClaimEmail.new(
        hashed_email: identifier.digest,
        user_id: user_id,
        email_verified_at: Time.zone.now
      ).execute!
    end
  end

  def unclaim(identifier)
    if identifier.phone?
      Authentication::Commands::UnclaimPhone.new(
        hashed_phone: identifier.digest,
        user_id: user_id
      ).execute!
    else
      Authentication::Commands::UnclaimEmail.new(
        hashed_email: identifier.digest,
        user_id: user_id
      ).execute!
    end
  end
end
