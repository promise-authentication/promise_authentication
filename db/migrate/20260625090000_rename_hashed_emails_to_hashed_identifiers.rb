class RenameHashedEmailsToHashedIdentifiers < ActiveRecord::Migration[8.0]
  # The hashed_emails table becomes the generic hashed_identifiers table:
  # same rows, same digests, just renamed and extended with an identifier_type
  # column. Done in place so existing e-mail rows are preserved without copying.
  def change
    rename_table :authentication_hashed_emails, :authentication_hashed_identifiers
    rename_column :authentication_hashed_identifiers, :email_verified_at, :verified_at
    add_column :authentication_hashed_identifiers, :identifier_type, :string, null: false, default: 'email'
    add_index :authentication_hashed_identifiers, :user_id
  end
end
