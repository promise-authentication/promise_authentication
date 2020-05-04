# Preview all emails at http://localhost:3000/rails/mailers/password_mailer
class PasswordMailerPreview < ActionMailer::Preview
  def unknown_mail
    PasswordMailer.with(email: 'hello@world.com').unknown_mail
  end

  def ping
    PasswordMailer.with(user_id: SecureRandom.uuid).ping
  end

  def recover_password
    PasswordMailer.with(user_id: SecureRandom.uuid, secret_key: SecureRandom.uuid, email: 'hello@example.com').recover_password
  end
end
