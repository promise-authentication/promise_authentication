# Read model mapping an identifier #digest -> user_id. Holds both e-mail and
# phone identifiers (see the identifier_type column). Should only ever contain
# claimed, verified identifiers. Built by Authentication::EventListener from
# the Email/Phone claim events.
class Authentication::HashedIdentifier < ApplicationRecord
  validates :user_id, presence: true

  # Back-compat alias: this column used to be email_verified_at.
  alias_attribute :email_verified_at, :verified_at

  def self.find_by_identifier(identifier)
    find_by(id: identifier.digest)
  end

  def self.user_id_for(identifier)
    find(identifier.digest).user_id
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
