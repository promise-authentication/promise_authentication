class Authentication::Services::PrepareEmailForValidation
  include ActiveModel::Model

  attr_accessor :email, :relying_party, :login_configuration

  def verifier
    @verifier = EmailVerificationCode.find_by_cleartext(email)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def verify!(code)
    return false if verifier.nil? || code.nil?

    verifier.code.upcase == code.upcase
  end

  def reset!
    verifier&.destroy
    MagicLink.reset_for!(Authentication::HashedEmail.from_cleartext(email))
    @verifier = nil
  end

  def generate_and_send_verification_code!(old_code: nil)
    reset!
    hashed_email = Authentication::HashedEmail.from_cleartext(email)
    code = EmailVerificationCode::HumanReadableCode.generate(4..4)

    # If an old code is provided, we need to make sure the new code
    # has a different first character to avoid confusion.
    code = EmailVerificationCode::HumanReadableCode.generate(4..4) while code[0] == old_code[0] if old_code

    magic_link_token = nil

    ActiveRecord::Base.transaction do
      EmailVerificationCode.create!(
        id: hashed_email,
        code: code
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
