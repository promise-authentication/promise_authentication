class Authentication::Services::ChangeEmail
  include ActiveModel::Model

  attr_accessor :user_id, :confirmation_code, :new_email

  validates :user_id, :confirmation_code, :new_email, presence: true

  def call
    # Verify the confirmation code
    verifier = Authentication::Services::PrepareEmailForValidation.new(
      email: new_email
    )
    if verifier.verify!(confirmation_code)
      # Update the user's email
      Authentication::Commands::ClaimEmail.new(
        hashed_email: Authentication::HashedEmail.from_cleartext(new_email),
        user_id: user_id,
        email_verified_at: Time.zone.now
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
