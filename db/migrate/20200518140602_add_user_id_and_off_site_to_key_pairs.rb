class AddUserIdAndOffSiteToKeyPairs < ActiveRecord::Migration[6.0]
  def change
    add_column :authentication_key_pairs, :user_id, :string
    add_column :authentication_key_pairs, :off_site_public_key_base64, :string
  end
end
