class Authentication::Commands::UpdateVault < Command
  attr_accessor :user_id, :encrypted_personal_data
  alias_method :aggregate_id, :user_id

  validates :encrypted_personal_data, presence: true

  def aggregate_class
    Authentication::Human
  end

  def call(vault)
    vault.update_vault(encrypted_personal_data: encrypted_personal_data)
  end
end
