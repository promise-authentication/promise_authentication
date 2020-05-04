class Authentication::Services::ChangeEmail
  include ActiveModel::Model

  attr_accessor :user_id, :old_email, :new_email

  def call!
    ActiveRecord::Base.transaction do
      hashed_new_email = Authentication::HashedEmail.from_cleartext(new_email)

      Authentication::Commands::ClaimEmail.new(
        user_id: user_id,
        hashed_email: hashed_new_email
      ).execute!

      hashed_old_email = Authentication::HashedEmail.from_cleartext(old_email)
      Authentication::Commands::ReleaseEmail.new(
        user_id: user_id,
        hashed_email: hashed_old_email
      ).execute!
    end
  end

end

