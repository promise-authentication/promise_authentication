class Authentication::Commands::ClaimIdentity < Command
  attr_accessor :id, :relying_party_id
  alias_method :aggregate_id, :id

  validates :id, :relying_party_id, presence: true

  def aggregate_class
    Authentication::Identity
  end

  def call(identity)
    identity.claim(relying_party_id: relying_party_id)
  end
end
