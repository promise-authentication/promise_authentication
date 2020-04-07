class Authentication::Services::Authenticate
  include ActiveModel::Model
  attr_accessor :email, :password

  validates :email, :password, presence: { message: 'goes here' }

  def user_id
    get_user_id_from_current_user || get_user_id_from_current_user
  end

  private

  def get_user_id_from_current_user
    current_user_id = Authentication::EncryptedEmail.user_id_for_cleartext(email)

    return nil unless current_user_id.present?

    return current_user_id if Authentication::Password.match!(current_user_id, password)
  end

  def get_user_id_from_new_user
    new_user_id = SecureRandom.uuid

    encrypted_email = Authentication::EncryptedEmail.from_cleartext(email)

    Authentication::Commands::ClaimEmail.(
      user_id: new_user_id,
      encrypted_email: encrypted_email
    )

    salt = SecureRandom.uuid
    hashed_password = Authentication::Password.hash(password, salt)

    Authentication::Commands::AddPassword.(
      user_id: new_user_id,
      salt: salt,
      hashed_password: hashed_password
    )

    vault = Authentication::Vault.new(key: password)
    vault.add_email email

    Authentication::Commands::UpdateVault.(
      user_id: new_user_id,
      encrypted_content: vault.encypted_content
    )

    new_user_id
  end

end
