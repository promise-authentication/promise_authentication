class Authentication::RelyingPartyEmail < ApplicationRecord
  validates :hashed_email, :relying_party_id, presence: true
end
