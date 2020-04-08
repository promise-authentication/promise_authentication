class Authentication::Human
  include AggregateRoot

  def initialize(user_id)
    @user_id = user_id
  end

  def set_password(digest:, vault_key_salt:)
    apply Authentication::Events::PasswordSet.new(data: {
      user_id: @user_id,
      digest: digest,
      vault_key_salt: vault_key_salt
    })
  end

  def update_vault(encrypted_personal_data:)
    apply Authentication::Events::VaultUpdated.new(data: {
      user_id: @user_id,
      encrypted_personal_data: encrypted_personal_data
    })
  end

  def apply_password_set(event)
  end

  def apply_vault_updated(event)
  end
end
