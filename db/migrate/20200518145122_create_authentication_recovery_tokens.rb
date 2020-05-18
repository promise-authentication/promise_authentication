class CreateAuthenticationRecoveryTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_recovery_tokens do |t|
      t.string :user_id
      t.string :token

      t.timestamps

      t.index :token
    end
  end
end
