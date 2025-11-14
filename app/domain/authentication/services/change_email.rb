class Authentication::Services::ChangeEmail
  include ActiveModel::Model

  attr_accessor :user_id, :confirmation_code, :from_email, :to_email

  validates :user_id, :confirmation_code, :from_email, :to_email, presence: true

  def call
    # Verify the confirmation code
    verifier = Authentication::Services::PrepareEmailForValidation.new(
      email: to_email
    )
    if verifier.verify!(confirmation_code)
      # First claim the new one
      Authentication::Commands::ClaimEmail.new(
        hashed_email: Authentication::HashedEmail.from_cleartext(to_email),
        user_id: user_id,
        email_verified_at: Time.zone.now
      ).execute!
      # Then unclaim the old one
      Authentication::Commands::UnclaimEmail.new(
        hashed_email: Authentication::HashedEmail.from_cleartext(from_email),
        user_id: user_id
      ).execute!

      # Optionally, reset the verification code after successful change
      verifier.reset!

      true
    else
      errors.add(:confirmation_code, 'is invalid')
      false
    end
  end
end
