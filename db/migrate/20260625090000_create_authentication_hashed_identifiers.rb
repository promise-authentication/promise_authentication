class CreateAuthenticationHashedIdentifiers < ActiveRecord::Migration[8.0]
  def up
    create_table :authentication_hashed_identifiers, id: :string do |t|
      t.string :user_id
      t.string :identifier_type, null: false, default: 'email'
      t.datetime :verified_at

      t.timestamps
    end
    add_index :authentication_hashed_identifiers, :user_id

    # Backfill the existing e-mail-only identifiers.
    execute <<~SQL.squish
      INSERT INTO authentication_hashed_identifiers
        (id, user_id, identifier_type, verified_at, created_at, updated_at)
      SELECT id, user_id, 'email', email_verified_at, created_at, updated_at
      FROM authentication_hashed_emails
    SQL

    drop_table :authentication_hashed_emails
  end

  def down
    create_table :authentication_hashed_emails, id: :string do |t|
      t.string :user_id

      t.timestamps
      t.datetime :email_verified_at, default: nil
    end

    execute <<~SQL.squish
      INSERT INTO authentication_hashed_emails
        (id, user_id, email_verified_at, created_at, updated_at)
      SELECT id, user_id, verified_at, created_at, updated_at
      FROM authentication_hashed_identifiers
      WHERE identifier_type = 'email'
    SQL

    drop_table :authentication_hashed_identifiers
  end
end
