class AddBounceTrackingToEmailVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    change_table :email_verification_codes, bulk: true do |t|
      # Opaque per-mail token, sent as an X-Promise-Verification header so
      # a bounce report can be matched back without storing the address.
      t.string :delivery_token
      # Throttles the Scaleway activity lookup from the status poll.
      t.datetime :delivery_checked_at
      t.datetime :bounced_at
      # One of EmailVerificationCode::BOUNCE_REASONS — never an address
      # or the raw SMTP message.
      t.string :bounce_reason
    end
    add_index :email_verification_codes, :delivery_token, unique: true
  end
end
