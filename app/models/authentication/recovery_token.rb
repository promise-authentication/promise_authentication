class Authentication::RecoveryToken < ApplicationRecord
  # A recovery token unlocks a password reset, so it should not live forever.
  EXPIRES_AFTER = 1.hour

  # Tokens still within their validity window.
  scope :active, -> { where(created_at: EXPIRES_AFTER.ago..) }

  def expired?
    created_at < EXPIRES_AFTER.ago
  end
end
