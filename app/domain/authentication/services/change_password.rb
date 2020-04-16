class Authentication::Services::ChangePassword
  include ActiveModel::Model

  attr_accessor :user_id, :current_password, :new_password

  validates :user_id, :current_password, :new_password, presence: true

  def new_salt
    hashed = Authentication::Password.find(user_id)
    hashed.match!(current_password)

    current_vault_key = Authentication::Vault.key_from(current_password, hashed.vault_key_salt)

    personal_data = Authentication::Vault.personal_data(user_id, current_vault_key)

    new_vault_key_salt = SecureRandom.uuid
    digest = Authentication::Password.digest_from(new_password)

    Authentication::Commands::AddPassword.new(
      user_id: user_id,
      vault_key_salt: new_vault_key_salt,
      digest: digest
    ).execute!

    new_vault_key = Authentication::Vault.key_from(new_password, new_vault_key_salt)
    cipher = Authentication::Vault.new(key: new_vault_key).encrypt(personal_data)

    Authentication::Commands::UpdateVault.new(
      user_id: user_id,
      encrypted_personal_data: cipher
    ).execute!

    new_vault_key_salt
  end
end

