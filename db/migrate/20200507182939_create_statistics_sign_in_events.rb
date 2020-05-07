class CreateStatisticsSignInEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :statistics_sign_in_events do |t|
      t.string :token_id
      t.string :relying_party_id
      t.string :user_id

      t.timestamps

      t.index :relying_party_id
    end
  end
end
