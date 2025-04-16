class Authentication::Commands::ClaimEmail < Command
  attr_accessor :hashed_email, :user_id, :email_verified_at
  alias aggregate_id hashed_email

  validates :hashed_email, presence: true

  def aggregate_class
    Authentication::Email
  end

  def call(email)
    email.claim(
      user_id: user_id,
      email_verified_at: email_verified_at
    )
  end
end
