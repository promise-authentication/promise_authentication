class EmailVerificationMailer < ApplicationMailer
  def verify_email
    @email = params[:email]
    @code = params[:code]
    @relying_party_name = params[:relying_party_name]

    subject = I18n.t(
      'email_verification_mailer.verify_email.subject',
      code: @code,
      relying_party: @relying_party_name.presence || 'Promise'
    )

    from_name = [
      @relying_party_name.presence,
      'Promise'
    ].compact.join(' via ')

    mail(
      to: @email,
      from: "#{from_name} <hello@promiseauthentication.org>",
      subject: subject
    )
  end
end
