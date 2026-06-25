# Starts a password recovery for an identifier.
#
# E-mail: sends a recovery link (the historical behaviour).
# Phone:  sends a short code by SMS that, once entered, unlocks the
#         server-side recovery token. We never send links to phones.
class Authentication::Services::SendRecovery
  include ActiveModel::Model

  attr_accessor :identifier, :locale, :relying_party

  def call
    user_id = Authentication::HashedIdentifier.user_id_for(identifier)

    if user_id.blank?
      notify_unknown
      return
    end

    identifier.phone? ? start_phone_recovery(user_id) : send_recovery_email(user_id)
  end

  private

  def send_recovery_email(user_id)
    token = create_token(user_id)
    PasswordMailer.with(
      token: token,
      email: identifier.value,
      locale: locale,
      relying_party_name: relying_party&.name
    ).recover_password.deliver_now
  end

  def start_phone_recovery(user_id)
    # Mint the recovery token now; it stays server-side and is unlocked by the
    # SMS code the user enters next.
    create_token(user_id)

    Authentication::Services::PrepareIdentifierForValidation.new(
      identifier: identifier,
      relying_party: relying_party
    ).generate_and_send_verification_code!
  end

  def create_token(user_id)
    token = SecureRandom.uuid
    Authentication::RecoveryToken.create(token: token, user_id: user_id)
    token
  end

  def notify_unknown
    # Don't reveal whether a phone number is registered.
    return if identifier.phone?

    PasswordMailer.with(email: identifier.value, locale: locale).unknown_mail.deliver_now
  end
end
