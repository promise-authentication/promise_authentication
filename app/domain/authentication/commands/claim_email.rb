class Authentication::Commands::ClaimEmail < Command
  attr_accessor :hashed_email, :user_id
  alias_method :aggregate_id, :hashed_email

  validates :hashed_email, presence: true

  def aggregate_class
    Authentication::Email
  end

  def call(email)
    email.claim(user_id: user_id)
  end
end
