class Authentication::Identity
  include AggregateRoot

  class AlreadyClaimed < StandardError; end

  attr_accessor :id, :relying_party_ids

  def initialize(id)
    @id = id
    @relying_party_ids = []
  end

  def claim(relying_party_id:)
    raise AlreadyClaimed if relying_party_ids.include?(relying_party_id)

    apply Authentication::Events::IdentityClaimed.new(data: {
      id: @id,
      relying_party_id: relying_party_id
    })
  end

  def apply_identity_claimed(event)
    @relying_party_ids << event.data[:relying_party_id]
  end

end
