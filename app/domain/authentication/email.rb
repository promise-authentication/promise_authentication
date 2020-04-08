class Authentication::Email
  include AggregateRoot

  class AlreadyClaimed < StandardError; end

  def initialize(hashed_email)
    @hashed_email = hashed_email
    @claimed = false
  end

  def claim(user_id:)
    raise AlreadyClaimed if @claimed

    apply Authentication::Events::EmailClaimed.new(data: {
      user_id: user_id,
      hashed_email: @hashed_email
    })
  end

  def apply_email_claimed(event)
    @claimed = true
  end
end
