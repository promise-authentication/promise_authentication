class Authentication::IdToken
  include ActiveModel::Model

  attr_accessor :sub, :aud, :iat, :iss, :nonce, :jti

  def self.generate_key_pair
    ecdsa_key = OpenSSL::PKey::EC.new 'secp521r1'
    ecdsa_key.generate_key
    ecdsa_public = OpenSSL::PKey::EC.new ecdsa_key
    ecdsa_public.private_key = nil

    return {
      private: ecdsa_key.to_pem,
      public: ecdsa_public.to_pem
    }
  end

  def to_s
    JWT.encode(payload, Rails.configuration.jwt_private_key, 'ES512').encode('utf-8')
  end

  def self.parse(string)
    decoded_token = JWT.decode string, Rails.configuration.jwt_public_key, true, { algorithm: 'ES512' }
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
