require 'json/jwt'

module Dpop
  class Proof
    class InvalidProof < StandardError; end

    TYP = 'dpop+jwt'.freeze
    SUPPORTED_ALGS = %w[ES256 ES384 ES512 RS256 PS256].freeze
    DEFAULT_SKEW = 60
    JTI_TTL = 120

    attr_reader :jkt, :jti

    def self.verify!(header_value, http_method:, http_url:, clock_skew: DEFAULT_SKEW, now: Time.now)
      raise InvalidProof, 'missing DPoP header' if header_value.blank?

      new(header_value, http_method: http_method, http_url: http_url, clock_skew: clock_skew, now: now).tap(&:verify!)
    end

    def initialize(token, http_method:, http_url:, clock_skew:, now:)
      @token = token
      @http_method = http_method.to_s.upcase
      @http_url = canonical_url(http_url)
      @clock_skew = clock_skew
      @now = now
    end

    def verify!
      header, payload = decode_and_verify_signature!
      verify_header!(header)
      verify_payload!(payload)
      @jti = payload['jti']
      @jkt = JSON::JWK.new(header['jwk']).thumbprint
      claim_jti!
      self
    end

    private

    def decode_and_verify_signature!
      header = unverified_header
      raise InvalidProof, 'unsupported alg' unless SUPPORTED_ALGS.include?(header['alg'])
      raise InvalidProof, 'missing jwk in header' unless header['jwk'].is_a?(Hash)

      key = JSON::JWK.new(header['jwk']).to_key
      payload, verified_header = JWT.decode(@token, key, true, algorithm: header['alg'])
      [verified_header, payload]
    rescue JWT::DecodeError, JWT::VerificationError, OpenSSL::PKey::PKeyError => e
      raise InvalidProof, "signature invalid: #{e.class}"
    end

    def unverified_header
      _payload, header = JWT.decode(@token, nil, false)
      header
    rescue JWT::DecodeError => e
      raise InvalidProof, "malformed proof: #{e.class}"
    end

    def verify_header!(header)
      raise InvalidProof, 'wrong typ' unless header['typ'] == TYP
    end

    def verify_payload!(payload)
      raise InvalidProof, 'wrong htm' unless payload['htm'].to_s.upcase == @http_method
      raise InvalidProof, 'wrong htu' unless canonical_url(payload['htu']) == @http_url
      raise InvalidProof, 'missing jti' if payload['jti'].blank?

      iat = payload['iat']
      raise InvalidProof, 'missing iat' unless iat.is_a?(Integer)

      now_i = @now.to_i
      raise InvalidProof, 'iat too far in past' if iat < now_i - @clock_skew
      raise InvalidProof, 'iat too far in future' if iat > now_i + @clock_skew
    end

    def claim_jti!
      key = "dpop:jti:#{@jti}"
      if Rails.cache.exist?(key)
        raise InvalidProof, 'jti replayed'
      end
      Rails.cache.write(key, true, expires_in: JTI_TTL)
    end

    def canonical_url(url)
      return nil if url.blank?
      uri = URI.parse(url.to_s)
      uri.fragment = nil
      uri.query = nil
      uri.to_s
    end
  end
end
