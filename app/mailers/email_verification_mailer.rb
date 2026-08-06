class EmailVerificationMailer < ApplicationMailer
  def verify_email
    @email = params[:email]
    @code = params[:code]
    @relying_party_name = params[:relying_party_name]
    @magic_link_url = params[:magic_link_token].presence &&
                      magic_registration_url(token: params[:magic_link_token])

    # Mails rarely arrive from dev machines — log the link so the flow
    # can be exercised locally by pasting it into the browser.
    Rails.logger.info "[magic-link] #{@email}: #{@magic_link_url}" if Rails.env.development? && @magic_link_url

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
