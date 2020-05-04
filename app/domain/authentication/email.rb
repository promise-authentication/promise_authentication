class Authentication::Email
  include AggregateRoot

  class AlreadyClaimed < StandardError; end
  class AlreadyClaimedByYou < StandardError; end
  class NotYoursToRelease < StandardError; end

  def initialize(hashed_email)
    @hashed_email = hashed_email
    @claimed = false
    @user_id = nil
  end

  def claim(user_id:)
    raise AlreadyClaimedByYou if @user_id == user_id
    raise AlreadyClaimed if @claimed

    apply Authentication::Events::EmailClaimed.new(data: {
      user_id: user_id,
      hashed_email: @hashed_email
    })
  end

  def release(user_id:)
    raise NotYoursToRelease unless @user_id == user_id

    apply Authentication::Events::EmailReleased.new(data: {
      user_id: user_id,
      hashed_email: @hashed_email
    })
  end

  def apply_email_claimed(event)
    @claimed = true
    @user_id = event.data[:user_id]
  end

  def apply_email_released(event)
    @claimed = false
    @user_id = nil
  end
end
