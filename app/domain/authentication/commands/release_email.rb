class Authentication::Commands::ReleaseEmail < Command
  attr_accessor :hashed_email, :user_id
  alias_method :aggregate_id, :hashed_email

  validates :hashed_email, :user_id, presence: true

  def aggregate_class
    Authentication::Email
  end

  def call(email)
    email.release(user_id: user_id)
  end
end
