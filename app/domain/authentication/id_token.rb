class Authentication::IdToken
  include ActiveModel::Model

  attr_accessor :sub, :aud, :iat, :iss, :nonce, :jti

  def self.current
    Trust::Certificate.current
  end

  def to_s
    cert = self.class.current
    jwk = cert.public_key.to_jwk
    kid = jwk["kid"]
    JWT.encode(payload, self.class.current.private_key, 'ES512', kid: kid).encode('utf-8')
  end

  def self.parse(string)
    decoded_token = JWT.decode string, current.public_key, true, { algorithm: 'ES512' }
    self.new(decoded_token.first)
  end

  def payload
    {
      jti: jti,
      sub: sub,
      aud: aud,
      iss: 'https://promiseauthentication.org',
      iat: (iat || Time.now).to_i,
      nonce: nonce
    }.compact
  end
end
