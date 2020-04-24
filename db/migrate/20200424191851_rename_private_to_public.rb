class RenamePrivateToPublic < ActiveRecord::Migration[6.0]
  def change
    rename_column :authentication_key_pairs, :private_key_cipher_base64, :public_key_base64
  end
end
