module Authentication::EventListener
  module_function

  def call(event)
    case event
    when Authentication::Events::EmailClaimed
      email = Authentication::HashedEmail.find_or_initialize_by(id: event.data[:hashed_email])
      email.user_id = event.data[:user_id]
      email.save
    when Authentication::Events::PasswordSet
      password = Authentication::Password.find_or_create_by(id: event.data[:user_id])
      password.digest = event.data[:digest]
      password.vault_key_salt = event.data[:vault_key_salt]
      password.save
    when Authentication::Events::VaultUpdated
      vault = Authentication::VaultContent.find_or_initialize_by(id: event.data[:user_id])
      vault.encrypted_personal_data = event.data[:encrypted_personal_data]
      vault.save

    end
  end
end

