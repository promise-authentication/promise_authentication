class Authentication::Phone
  include AggregateRoot

  class AlreadyClaimed < StandardError; end
  class NotClaimed < StandardError; end

  def initialize(hashed_phone)
    @hashed_phone = hashed_phone
    @claimed = false
  end

  def claim(user_id:, phone_verified_at: nil)
    raise AlreadyClaimed if @claimed

    apply Authentication::Events::PhoneClaimed.new(data: {
                                                     user_id: user_id,
                                                     hashed_phone: @hashed_phone,
                                                     phone_verified_at: phone_verified_at
                                                   })
  end

  def unclaim(user_id:)
    raise NotClaimed unless @claimed

    apply Authentication::Events::PhoneUnclaimed.new(data: {
                                                       user_id: user_id,
                                                       hashed_phone: @hashed_phone
                                                     })
  end

  def apply_phone_claimed(_event)
    @claimed = true
  end

  def apply_phone_unclaimed(_event)
    @claimed = false
  end
end
