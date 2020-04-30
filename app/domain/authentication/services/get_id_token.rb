class Authentication::Services::GetIdToken
  include ActiveModel::Model

  attr_accessor :user_id, :relying_party_id, :vault_key, :nonce

  validates :user_id, :relying_party_id, :vault_key, presence: true

  def id_token
    id = Existing.(user_id, relying_party_id, vault_key) ||
      Register.(user_id, relying_party_id, vault_key)

    Authentication::IdToken.new(
      nonce: nonce,
      sub: id,
      aud: relying_party_id
    )
  end
end
