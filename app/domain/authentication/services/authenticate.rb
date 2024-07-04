class Authentication::Services::Authenticate
  include ActiveModel::Model

  EmailConfirmationError = Class.new(StandardError)

  attr_writer :email
  attr_accessor :password, :relying_party_id, :exisiting_account
  attr_reader :user_id, :vault_key, :existing_account, :should_confirm_email

  validates :email, :password, presence: true

  def email
    clean_email(@email)
  end

  def vault_key_base64
    Base64.strict_encode64(vault_key)
  end

  def relying_party
    Authentication::RelyingParty.find(relying_party_id)
  end

  def existing!
    @user_id, @vault_key = Existing.call(email, password)
    @existing_account = !!@user_id
  end

  def call!
    existing!
    self
  end

  def clean_email(email)
    email&.strip&.downcase
  end

  def register!(email_confirmation:)
    raise EmailConfirmationError if email != clean_email(email_confirmation)

    @user_id, @vault_key = Register.call(email: email,
                                         password: password,
                                         relying_party_id: relying_party&.id,
                                         legacy_account_user_id: legacy_account_user_id,
                                         relying_party_knows_password: legacy_account_user_id.present?)
    self
  end

  def legacy_account_user_id
    return unless relying_party&.knows_legacy_account?(email)

    relying_party.legacy_account_user_id_for(
      email,
      password
    )
  end
end
