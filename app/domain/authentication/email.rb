class Authentication::Email
  include AggregateRoot

  class AlreadyClaimed < StandardError; end
  class NotClaimed < StandardError; end

  def initialize(hashed_email)
    @hashed_email = hashed_email
    @claimed = false
  end

  def claim(user_id:, email_verified_at: nil)
    raise AlreadyClaimed if @claimed

    apply Authentication::Events::EmailClaimed.new(data: {
                                                     user_id: user_id,
                                                     hashed_email: @hashed_email,
                                                     email_verified_at: email_verified_at
                                                   })
  end

  def unclaim(user_id:)
    raise NotClaimed unless @claimed

    apply Authentication::Events::EmailUnclaimed.new(data: {
                                                       user_id: user_id,
                                                       hashed_email: @hashed_email
                                                     })
  end

  def apply_email_claimed(_event)
    @claimed = true
  end

  def apply_email_unclaimed(_event)
    @claimed = false
  end
end
