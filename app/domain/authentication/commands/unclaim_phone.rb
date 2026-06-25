class Authentication::Commands::UnclaimPhone < Command
  attr_accessor :hashed_phone, :user_id
  alias aggregate_id hashed_phone

  validates :hashed_phone, presence: true

  def aggregate_class
    Authentication::Phone
  end

  def call(phone)
    phone.unclaim(
      user_id: user_id
    )
  end
end
