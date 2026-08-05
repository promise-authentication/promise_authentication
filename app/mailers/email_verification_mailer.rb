class EmailVerificationMailer < ApplicationMailer
  def verify_email
    @email = params[:email]
    @code = params[:code]
    @relying_party_name = params[:relying_party_name]
    @magic_link_url = params[:magic_link_token].presence &&
                      magic_registration_url(token: params[:magic_link_token])

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
