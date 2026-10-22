class EmailVerificationMailer < ApplicationMailer
  FROM_ADDRESS = 'hello@promiseauthentication.org'.freeze

  # These are also used by the verify_email page to render a faithful
  # mockup of the mail — keep them the single source of truth.
  def self.subject_for(code:, relying_party_name: nil)
    I18n.t(
      'email_verification_mailer.verify_email.subject',
      code: code,
      relying_party: relying_party_name.presence || 'Promise'
    )
  end

  def self.from_name_for(relying_party_name: nil)
    [relying_party_name.presence, 'Promise'].compact.join(' via ')
  end

  def self.magic_link_button_label(relying_party_name: nil)
    if relying_party_name.present?
      I18n.t('email_verification_mailer.verify_email.magic_link_button_with_client', client: relying_party_name)
    else
      I18n.t('email_verification_mailer.verify_email.magic_link_button')
    end
  end

  def verify_email
    @email = params[:email]
    @code = params[:code]
    @relying_party_name = params[:relying_party_name]
    @magic_link_url = params[:magic_link_token].presence &&
                      magic_registration_url(token: params[:magic_link_token])
    @magic_link_label = self.class.magic_link_button_label(relying_party_name: @relying_party_name)

    # Bounce handling (see Bounces): the token lets a delivery report be
    # matched to the code, and the envelope sender (Return-Path) steers
    # such reports to the mailbox we read instead of a human's inbox.
    headers[Bounces::TOKEN_HEADER] = params[:delivery_token] if params[:delivery_token].present?

    mail(
      {
        to: @email,
        from: "#{self.class.from_name_for(relying_party_name: @relying_party_name)} <#{FROM_ADDRESS}>",
        subject: self.class.subject_for(code: @code, relying_party_name: @relying_party_name),
        return_path: Bounces.return_path
      }.compact
    )
  end
end
