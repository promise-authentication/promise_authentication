class AddResendCountToEmailVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :email_verification_codes, :resend_count, :integer, default: 0, null: false
  end
end
