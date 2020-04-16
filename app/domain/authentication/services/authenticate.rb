class Authentication::Services::Authenticate
  include ActiveModel::Model

  attr_accessor :email, :password

  validates :email, :password, presence: true

  def email
    @email&.downcase
  end

  def user_id_and_salt
    Existing.(email, password) || Register.(email, password)
  end
end
