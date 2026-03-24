# Preview all emails at http://localhost:3000/rails/mailers/password_mailer
class EmailVerificationMailerPreview < ActionMailer::Preview
  def verify_email
    code = "KSD"
    EmailVerificationMailer.with(
      email: "hello@world.com",
      code: code,
      relying_party_name: "Oase"
    ).verify_email
  end
end
