class Authentication::Commands::UnclaimEmail < Command
  attr_accessor :hashed_email, :user_id
  alias aggregate_id hashed_email

  validates :hashed_email, presence: true

  def aggregate_class
    Authentication::Email
  end

  def call(email)
    email.unclaim(
      user_id: user_id
    )
  end
end
