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

  def recover_password
    @email = params[:email]
    @token = params[:token]

    @url = token_recoveries_url(token_id: @token, locale: I18n.locale)

    mail(
      to: @email,
      subject: I18n.t('password_mailer.recover_password.subject')
    )
  end
end
