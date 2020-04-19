class CreateAuthenticationKeyPairs < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_key_pairs, id: :string do |t|
      # t.string :public_key_base64 # This is actually the id
      t.string :private_key_cipher_base64

      t.timestamps
    end
  end
end
