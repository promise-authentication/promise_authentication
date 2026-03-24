class CreateEmailVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :email_verification_codes, id: :string do |t|
      t.string :code

      t.timestamps
    end
  end
end
