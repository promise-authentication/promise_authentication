class Authentication::Request
  include ActiveModel::Model
  attr_accessor :email, :password

  validates :email, :password, presence: { message: 'goes here' }

  validates :password, length: { minimum: 30, message: 'not valid. Try again' }
end
