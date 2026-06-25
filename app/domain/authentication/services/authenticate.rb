class Authentication::Services::Authenticate
  include ActiveModel::Model

  EmailConfirmationError = Class.new(StandardError)

  attr_writer :email, :phone
  attr_accessor :password, :relying_party_id, :exisiting_account, :verified_at
  attr_reader :user_id, :vault_key, :existing_account

  validates :password, presence: true
  validate :identifier_must_be_present

  # The identifier the user is authenticating with. A phone number takes
  # precedence when both are (somehow) supplied.
  def identifier
    if @phone.present?
      Authentication::Identifier.phone(@phone)
    else
      Authentication::Identifier.email(@email)
    end
  end

  def identifier_type
    identifier.type
  end

  # Back-compat: the cleaned e-mail (nil for phone identifiers).
  def email
    return nil unless identifier.email?

    identifier.value
  end

  def phone
    return nil unless identifier.phone?

    identifier.value
  end

  # Back-compat alias used by the registration flow.
  def email_verified_at=(time)
    self.verified_at = time
  end

  def vault_key_base64
    Base64.strict_encode64(vault_key)
  end

  def relying_party
    Authentication::RelyingParty.find(relying_party_id)
  end

  def existing!
    @user_id, @vault_key = Existing.call(identifier, password)
    @existing_account = !!@user_id
  end

  def call!
    existing!
    self
  end

  def register!
    @user_id, @vault_key = Register.call(identifier: identifier,
                                         password: password,
                                         relying_party_id: relying_party&.id,
                                         legacy_account_user_id: legacy_account_user_id,
                                         verified_at: verified_at,
                                         relying_party_knows_password: legacy_account_user_id.present?)
    self
  end

  def legacy_account_user_id
    return unless identifier.email? && relying_party&.knows_legacy_account?(identifier.value)

    relying_party.legacy_account_user_id_for(
      identifier.value,
      password
    )
  end

  private

  # Login only requires a present identifier; format validation for new
  # sign-ups happens in the controller (EmailInquire / Phonelib).
  def identifier_must_be_present
    errors.add(identifier.type, :blank) if identifier.value.blank?
  end
end
