class CreateAuthenticationPasswords < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_passwords, id: :string do |t|
      t.binary :digest
      t.string :vault_key_salt
      t.timestamps
    end
  end
end
