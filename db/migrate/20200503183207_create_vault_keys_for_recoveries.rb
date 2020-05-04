class CreateVaultKeysForRecoveries < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_vault_keys_for_recoveries, id: :string do |t|
      t.string :key_pair_id
      t.text :vault_key_cipher_base64
      t.text :recoverable_vault_key_cipher_base64

      t.timestamps
    end
  end
end
