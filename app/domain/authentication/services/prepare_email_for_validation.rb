class Authentication::Services::PrepareEmailForValidation
  include ActiveModel::Model

  attr_accessor :email, :relying_party

  def verifier
    @verifier = EmailVerificationCode.find_by_cleartext(email)
  rescue ActiveRecord::RecordNotFound
    return nil
  end

  def verify!(code)
    verifier.code.upcase == code.upcase
  end

  def reset!
    verifier&.destroy
    @verifier = nil
  end

  def generate_and_send_verification_code!
    reset!
    hashed_email = Authentication::HashedEmail.from_cleartext(email)
    code = EmailVerificationCode::HumanReadableCode.generate(2..3)

    ActiveRecord::Base.transaction do
      EmailVerificationCode.create!(
        id: hashed_email,
        code: code
      )

      EmailVerificationMailer.with(
        email: email,
        code: code,
        relying_party_name: relying_party&.name
      ).verify_email.deliver_now
    end
  end
end
