class CreateAuthenticationVaultContents < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_vault_contents, id: :string do |t|
      t.binary :encrypted_personal_data
      t.timestamps
    end
  end
end
