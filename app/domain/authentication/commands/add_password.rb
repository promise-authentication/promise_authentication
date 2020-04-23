class Authentication::Commands::AddPassword < Command
  attr_accessor :digest, :vault_key_salt, :user_id, :encrypted_vault_key, :password_known_by_relying_party_id
  alias_method :aggregate_id, :user_id

  validates :digest, :vault_key_salt, :user_id, :encrypted_vault_key, presence: true

  def aggregate_class
    Authentication::Human
  end

  def call(human)
    human.set_password(
      digest: digest,
      vault_key_salt: vault_key_salt,
      encrypted_vault_key: encrypted_vault_key,
      password_known_by_relying_party_id: password_known_by_relying_party_id
    )
  end
end
