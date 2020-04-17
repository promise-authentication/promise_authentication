class Authentication::Services::ChangePassword
  include ActiveModel::Model

  attr_accessor :user_id, :current_password, :new_password
  attr_reader :new_vault_key

  validates :user_id, :current_password, :new_password, presence: true

  def call
    hashed = Authentication::Password.find(user_id)
    hashed.match!(current_password)

    current_vault_key = Authentication::Vault.key_from(current_password, hashed.vault_key_salt)

    personal_data = Authentication::Vault.personal_data(user_id, current_vault_key)

    @new_vault_key = Authentication::Services::SetPassword.new(
      user_id: user_id,
      password: new_password,
      personal_data: personal_data
    ).call
  end
end

