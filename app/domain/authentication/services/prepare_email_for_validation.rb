class Authentication::Services::PrepareEmailForValidation
  include ActiveModel::Model

  # After this many resends for the same pending registration, the user
  # has to go through "send new code" (Turnstile) again. Keeps the
  # wrong-code resend paths from being usable for mail bombing.
  MAX_RESENDS = 5

  attr_accessor :email, :relying_party, :login_configuration

  def verifier
    @verifier = EmailVerificationCode.active_for_cleartext(email)
  end

  def verify!(code)
    return false if verifier.nil? || code.nil?

    verifier.code.upcase == code.upcase
  end

  def can_resend?
    current = EmailVerificationCode.find_by_cleartext(email)
    current.nil? || current.resend_count < MAX_RESENDS
  end

  def reset!
    EmailVerificationCode.find_by_cleartext(email)&.destroy
    MagicLink.reset_for!(Authentication::HashedEmail.from_cleartext(email))
    @verifier = nil
  end

  def generate_and_send_verification_code!(old_code: nil)
    resend_count = old_code ? EmailVerificationCode.find_by_cleartext(email)&.resend_count.to_i + 1 : 0

    reset!
    EmailVerificationCode.sweep_expired!
    MagicLink.sweep_expired!

    hashed_email = Authentication::HashedEmail.from_cleartext(email)
    code = EmailVerificationCode::HumanReadableCode.generate(4..4)

    # If an old code is provided, we need to make sure the new code
    # has a different first character to avoid confusion.
    code = EmailVerificationCode::HumanReadableCode.generate(4..4) while code[0] == old_code[0] if old_code

    magic_link_token = nil

    ActiveRecord::Base.transaction do
      EmailVerificationCode.create!(
        id: hashed_email,
        code: code,
        resend_count: resend_count
      )

      # Only the registration flow gets a magic link — the change-email
      # flow also sends codes through this service, but its link would
      # wrongly land the user in registration.
      if login_configuration
        magic_link_token = MagicLink.issue!(
          hashed_email: hashed_email,
          payload: login_configuration.merge('email' => email, 'code' => code)
        )
      end
    end

    # Mails rarely arrive from dev machines — log the link so the flow
    # can be exercised locally by pasting it into the browser.
    if Rails.env.development? && magic_link_token
      url = Rails.application.routes.url_helpers.magic_registration_url(
        token: magic_link_token,
        **Rails.application.config.action_mailer.default_url_options
      )
      Rails.logger.info "[magic-link] #{email}: #{url}"
    end

    retries = 0
    max_retries = 3

    begin
      EmailVerificationMailer.with(
        email: email,
        code: code,
        relying_party_name: relying_party&.name,
        magic_link_token: magic_link_token
      ).verify_email.deliver_now
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      retries += 1
      raise e unless retries <= max_retries

      sleep(retries * 2)
      retry
    end

    verifier
  end
end
