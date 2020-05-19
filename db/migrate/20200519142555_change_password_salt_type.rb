class ChangePasswordSaltType < ActiveRecord::Migration[6.0]
  def change
    change_column :authentication_passwords, :vault_key_salt, :binary
  end
end
