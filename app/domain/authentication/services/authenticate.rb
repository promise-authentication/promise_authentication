class Authentication::Services::Authenticate
  include ActiveModel::Model

  attr_accessor :email, :password, :relying_party_id
  attr_reader :user_id, :vault_key
  attr_reader :newly_created_account

  validates :email, :password, presence: true

  def email
    @email&.downcase
  end

  def vault_key_base64
    Base64.strict_encode64(vault_key)
  end

  def relying_party
    Authentication::RelyingParty.find(relying_party_id)
  end

  def call!
    @user_id, @vault_key = Existing.(email, password)
    if @user_id
      @newly_created_account = false
    else

      legacy_account_user_id = nil
      if(relying_party&.knows_legacy_account?(email))
        legacy_account_user_id = relying_party.legacy_account_user_id_for(
          email,
          password
        )
      end

      @user_id, @vault_key = Register.(
        email: email,
        password: password,
        relying_party_id: relying_party&.id,
        legacy_account_user_id: legacy_account_user_id,
        relying_party_knows_password: legacy_account_user_id.present?
      )
      @newly_created_account = true
    end
    self
  end
end
