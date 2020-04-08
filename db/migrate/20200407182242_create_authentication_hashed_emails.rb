class CreateAuthenticationHashedEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_hashed_emails, id: :string do |t|
      t.string :user_id

      t.timestamps
    end
  end
end
