class Authentication::Services::MakeRecoverable
  include ActiveModel::Model

  attr_accessor :user_id
  attr_reader :secret_key
  attr_reader :email

  delegate :info, to: :keys

  def encrypt!(vault_key)
    key = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
    @secret_key = Base64.strict_encode64(key)

    box = RbNaCl::SimpleBox.from_secret_key(key)
    cipher = box.encrypt(vault_key)
    base64 = Base64.strict_encode64(cipher)
    keys.recoverable_vault_key_cipher_base64 = base64
    keys.save
  end

  def send!(email, locale)
    I18n.with_locale(locale) do
      PasswordMailer.with(email: email, user_id: user_id, secret_key: secret_key).recover_password.deliver_now
    end
  end

  private

  def keys
    @keys ||= Authentication::VaultKeysForRecovery.find(user_id)
  end

end
