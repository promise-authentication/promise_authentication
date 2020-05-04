class Authentication::Services::RecoverPassword
  include ActiveModel::Model

  attr_accessor :email, :locale

  def call
    current_user_id = Authentication::HashedEmail.user_id_for_cleartext(email)

    if current_user_id.blank?
      PasswordMailer.with(email: email, locale: locale).unknown_mail.deliver_now
    else
      PasswordMailer.with(user_id: current_user_id, email: email, locale: locale).ping.deliver_now
    end
  end
end

