class Authentication::Events::PasswordSet < DomainEvent
  def recoverable?
    data[:encrypted_vault_key].present?
  end
end
