class Authentication::Services::PrepareEmailForValidation
  include ActiveModel::Model

  attr_accessor :email, :relying_party

  def verifier
    @verifier = EmailVerificationCode.find_by_cleartext(email)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def verify!(code)
    verifier.code.upcase == code.upcase
  end

  def reset!
    verifier&.destroy
    @verifier = nil
  end

  def generate_and_send_verification_code!(old_code: nil)
    reset!
    hashed_email = Authentication::HashedEmail.from_cleartext(email)
    code = EmailVerificationCode::HumanReadableCode.generate(4..4)

    # If an old code is provided, we need to make sure the new code
    # has a different first character to avoid confusion.
    code = EmailVerificationCode::HumanReadableCode.generate(4..4) while code[0] == old_code[0] if old_code

    ActiveRecord::Base.transaction do
      EmailVerificationCode.create!(
        id: hashed_email,
        code: code
      )

      retries = 0
      max_retries = 3

      begin
        EmailVerificationMailer.with(
          email: email,
          code: code,
          relying_party_name: relying_party&.name
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
end
