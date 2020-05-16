class CreateAuthenticationRelyingPartyEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_relying_party_emails do |t|
      t.string :hashed_email
      t.string :relying_party_id

      t.timestamps

      t.index [:hashed_email, :relying_party_id], unique: true, name: 'lookup'
    end
  end
end
