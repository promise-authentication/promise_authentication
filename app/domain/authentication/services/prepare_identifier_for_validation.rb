# Generates a verification code for an identifier and delivers it through the
# right channel: e-mail for e-mail identifiers, SMS for phone identifiers.
class Authentication::Services::PrepareIdentifierForValidation
  include ActiveModel::Model

  attr_accessor :identifier, :relying_party

  def verifier
    VerificationCode.find_for(identifier)
  end

  def verify!(code)
    current = verifier
    return false if current.nil? || code.blank?

    current.code.casecmp?(code.to_s.strip)
  end

  def reset!
    verifier&.destroy
  end

  def generate_and_send_verification_code!(old_code: nil)
    reset!
    code = VerificationCode::HumanReadableCode.generate(4..4)

    # If an old code is provided, make sure the new code has a different first
    # character to avoid confusion.
    code = VerificationCode::HumanReadableCode.generate(4..4) while old_code && code[0] == old_code[0]

    ActiveRecord::Base.transaction do
      VerificationCode.create!(
        id: identifier.digest,
        code: code
      )
    end

    deliver(code)

    verifier
  end

  private

  def deliver(code)
    identifier.phone? ? deliver_sms(code) : deliver_email(code)
  end

  def deliver_email(code)
    retries = 0
    max_retries = 3

    begin
      EmailVerificationMailer.with(
        email: identifier.value,
        code: code,
        relying_party_name: relying_party&.name
      ).verify_email.deliver_now
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      retries += 1
      raise e unless retries <= max_retries

      sleep(retries * 2)
      retry
    end
  end

  def deliver_sms(code)
    body = I18n.t(
      'sms.verification_code',
      code: code,
      relying_party: relying_party&.name.presence || 'Promise'
    )
    # Domain-bound one-time-code line so iOS/Android can autofill the code
    # from the SMS (WebOTP). Must be the last line: "@domain #code".
    body += "\n@#{self.class.otp_domain} ##{code}"

    Authentication::Services::SmsSender.new(to: identifier.value, body: body).call
  end

  def self.otp_domain
    ENV.fetch('PROMISE_OTP_DOMAIN', 'promiseauthentication.org')
  end
end
