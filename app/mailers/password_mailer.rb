class PasswordMailer < ApplicationMailer
  def unknown_mail
    @email = params[:email]

    I18n.with_locale(params[:locale]) do
      mail(
        to: @email,
        subject: I18n.t('password_mailer.unknown_mail.subject')
      )
    end
  end

  def ping
    @user_id = params[:user_id]
    @email = params[:email]
    @locale = params[:locale]

    # Haha, yeah. I'm gonna get tired of this!
    # But when I do, that means that Promise is happening. 🤯
    mail(
      to: 'anderslemke@gmail.com',
      subject: "Recover password requested"
    )
  end

  def recover_password
    @email = params[:email]
    @user_id = params[:user_id]
    @secret_key = params[:secret_key]

    @url = key_recovery_url(id: @user_id, key_id: @secret_key, locale: I18n.locale)

    mail(
      to: @email,
      subject: I18n.t('password_mailer.recover_password.subject')
    )
  end
end
