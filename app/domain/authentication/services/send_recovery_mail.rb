class Authentication::Services::SendRecoveryMail
  include ActiveModel::Model

  attr_accessor :email, :locale

  def call
    current_user_id = Authentication::HashedEmail.user_id_for_cleartext(email)

    if current_user_id.blank?
      PasswordMailer.with(email: email, locale: locale).unknown_mail.deliver_now
    else
      token = SecureRandom.uuid
      Authentication::RecoveryToken.create(
        token: token,
        user_id: current_user_id
      )
      PasswordMailer.with(token: token, email: email, locale: locale).recover_password.deliver_now
    end
  end
end

