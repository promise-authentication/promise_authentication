class Authentication::Commands::ClaimPhone < Command
  attr_accessor :hashed_phone, :user_id, :phone_verified_at
  alias aggregate_id hashed_phone

  validates :hashed_phone, presence: true

  def aggregate_class
    Authentication::Phone
  end

  def call(phone)
    phone.claim(
      user_id: user_id,
      phone_verified_at: phone_verified_at
    )
  end
end
