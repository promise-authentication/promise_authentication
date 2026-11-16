require 'test_helper'

class Dpop::ProofTest < ActiveSupport::TestCase
  HTM = 'POST'.freeze
  HTU = 'https://promise.example/oauth2/token'.freeze

  setup do
    @key = OpenSSL::PKey::EC.generate('prime256v1')
    @jwk = JSON::JWK.new(@key).as_json.slice('kty', 'crv', 'x', 'y')
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test 'verifies a well-formed proof and exposes jkt + jti' do
    jti = SecureRandom.uuid
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i, jti: jti })

    proof = Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)

    assert_equal jti, proof.jti
    assert_equal JSON::JWK.new(@key).thumbprint, proof.jkt
  end

  test 'rejects a missing header' do
    error = assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(nil, http_method: HTM, http_url: HTU)
    end
    assert_match(/missing/i, error.message)
  end

  test 'rejects wrong typ' do
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i, jti: SecureRandom.uuid }, typ: 'jwt')

    assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
  end

  test 'rejects wrong htm' do
    token = sign_proof(payload: { htm: 'GET', htu: HTU, iat: Time.now.to_i, jti: SecureRandom.uuid })

    error = assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
    assert_match(/htm/, error.message)
  end

  test 'rejects wrong htu' do
    token = sign_proof(payload: { htm: HTM, htu: 'https://elsewhere.example/oauth2/token', iat: Time.now.to_i, jti: SecureRandom.uuid })

    error = assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
    assert_match(/htu/, error.message)
  end

  test 'tolerates htu with query/fragment' do
    token = sign_proof(payload: { htm: HTM, htu: "#{HTU}?foo=bar#frag", iat: Time.now.to_i, jti: SecureRandom.uuid })

    assert_nothing_raised do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: "#{HTU}?baz=1")
    end
  end

  test 'rejects iat too far in the past' do
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i - 600, jti: SecureRandom.uuid })

    assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
  end

  test 'rejects iat too far in the future' do
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i + 600, jti: SecureRandom.uuid })

    assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
  end

  test 'rejects missing jti' do
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i })

    assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
  end

  test 'rejects replayed jti within TTL' do
    jti = SecureRandom.uuid
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i, jti: jti })

    Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)

    assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
  end

  test 'rejects signature signed by a different key' do
    forged_key = OpenSSL::PKey::EC.generate('prime256v1')
    payload = { htm: HTM, htu: HTU, iat: Time.now.to_i, jti: SecureRandom.uuid }
    # JWK header claims our key, but token is signed by forged_key
    token = JWT.encode(payload, forged_key, 'ES256', typ: 'dpop+jwt', jwk: @jwk)

    assert_raises(Dpop::Proof::InvalidProof) do
      Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    end
  end

  test 'jkt matches RFC 7638 thumbprint of embedded jwk' do
    token = sign_proof(payload: { htm: HTM, htu: HTU, iat: Time.now.to_i, jti: SecureRandom.uuid })

    proof = Dpop::Proof.verify!(token, http_method: HTM, http_url: HTU)
    assert_equal JSON::JWK.new(@key).thumbprint, proof.jkt
  end

  private

  def sign_proof(payload:, typ: 'dpop+jwt', alg: 'ES256', jwk: @jwk, key: @key)
    JWT.encode(payload, key, alg, typ: typ, jwk: jwk)
  end
end
