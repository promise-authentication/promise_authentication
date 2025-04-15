class EmailVerificationMailer < ApplicationMailer
  def verify_email
    @email = params[:email]
    @code = params[:code]
    @relying_party_name = params[:relying_party_name]

    subject = I18n.t('email_verification_mailer.verify_email.subject', code: @code)

    mail(
      to: @email,
      subject: subject
    )
  end
end
