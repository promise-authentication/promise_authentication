# Backwards-compatible e-mail-to-e-mail wrapper around ChangeIdentifier.
class Authentication::Services::ChangeEmail < Authentication::Services::ChangeIdentifier
  attr_accessor :from_email, :to_email

  validates :from_email, :to_email, presence: true

  def from_identifier
    Authentication::Identifier.email(from_email)
  end

  def to_identifier
    Authentication::Identifier.email(to_email)
  end
end
