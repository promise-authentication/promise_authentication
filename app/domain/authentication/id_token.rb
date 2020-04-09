class Authentication::IdToken
  include ActiveModel::Model

  attr_accessor :sub, :aud

  def to_s
    JWT.encode payload, nil, 'none'
  end

  def self.parse(string)
  end

  private

  def payload
    {
      sub: sub,
      aud: aud,
      provider: 'promise',
      iat: Time.now.to_i,
    }
  end
end
