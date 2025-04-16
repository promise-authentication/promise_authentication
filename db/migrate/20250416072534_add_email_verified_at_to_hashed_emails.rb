class AddEmailVerifiedAtToHashedEmails < ActiveRecord::Migration[8.0]
  def change
    add_column :authentication_hashed_emails, :email_verified_at, :datetime, default: nil
  end
end
