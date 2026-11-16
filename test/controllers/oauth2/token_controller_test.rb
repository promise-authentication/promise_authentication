require 'test_helper'

class Oauth2::TokenControllerTest < ActionDispatch::IntegrationTest
  GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:token-exchange'.freeze
  ID_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:id_token'.freeze
  TOKEN_URL = 'http://www.example.com/oauth2/token'.freeze

  setup do
    Trust::Certificate.rotate!
    @id_token = Authentication::IdToken.new(
      sub: 'user-abc',
      aud: 'example.com',
      jti: SecureRandom.uuid
    ).to_s
    @device_key = OpenSSL::PKey::EC.generate('prime256v1')
    @device_jwk = JSON::JWK.new(@device_key).as_json.slice('kty', 'crv', 'x', 'y')
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test 'exchanges an id_token for a DPoP-bound access token' do
    post_token(dpop: dpop_proof)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'Bearer', body['token_type']
    assert_equal 'urn:ietf:params:oauth:token-type:access_token', body['issued_token_type']
    assert_equal 120, body['expires_in']

    key = Trust::Certificate.current.public_key
    decoded, header = JWT.decode(body['access_token'], key, true, { algorithm: 'ES512' })

    assert header['kid'], 'access token must include kid'
    assert_equal 'https://api.oase.app', decoded['aud']
    assert_equal 'user-abc', decoded['sub']
    assert_equal 'https://promiseauthentication.org', decoded['iss']
    assert decoded['exp'] > decoded['iat']
    assert decoded['jti']
    assert_equal JSON::JWK.new(@device_key).thumbprint, decoded.dig('cnf', 'jkt')
  end

  test 'issued access token verifies against published JWKS' do
    post_token(dpop: dpop_proof)
    access_token = JSON.parse(response.body)['access_token']

    get '/.well-known/jwks.json'
    jwks = JSON.parse(response.body)

    decoded, _header = JWT.decode(
      access_token,
      nil,
      true,
      algorithms: ['ES512'],
      jwks: { keys: jwks['keys'] }
    )

    assert_equal 'user-abc', decoded['sub']
  end

  test 'rejects an invalid subject_token' do
    post_token(dpop: dpop_proof, subject_token: 'not-a-jwt')

    assert_response :bad_request
    assert_equal 'invalid_grant', JSON.parse(response.body)['error']
  end

  test 'rejects request with missing audience' do
    post_token(dpop: dpop_proof, audience: nil)

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal 'invalid_request', body['error']
    assert_match(/audience/, body['error_description'])
  end

  test 'rejects request with unsupported grant_type' do
    post_token(dpop: dpop_proof, grant_type: 'authorization_code')

    assert_response :bad_request
    assert_equal 'invalid_request', JSON.parse(response.body)['error']
  end

  test 'rejects request with unsupported subject_token_type' do
    post_token(dpop: dpop_proof, subject_token_type: 'urn:ietf:params:oauth:token-type:access_token')

    assert_response :bad_request
    assert_equal 'invalid_request', JSON.parse(response.body)['error']
  end

  test 'rejects request with missing DPoP header' do
    post_token(dpop: nil)

    assert_response :bad_request
    assert_equal 'invalid_dpop_proof', JSON.parse(response.body)['error']
  end

  test 'rejects DPoP proof with wrong htm' do
    proof = dpop_proof(htm: 'GET')
    post_token(dpop: proof)

    assert_response :bad_request
    assert_equal 'invalid_dpop_proof', JSON.parse(response.body)['error']
  end

  test 'rejects DPoP proof with wrong htu' do
    proof = dpop_proof(htu: 'https://elsewhere.example/oauth2/token')
    post_token(dpop: proof)

    assert_response :bad_request
    assert_equal 'invalid_dpop_proof', JSON.parse(response.body)['error']
  end

  test 'rejects replayed DPoP jti' do
    proof = dpop_proof
    post_token(dpop: proof)
    assert_response :success

    post_token(dpop: proof)
    assert_response :bad_request
    assert_equal 'invalid_dpop_proof', JSON.parse(response.body)['error']
  end

  private

  def post_token(dpop:, subject_token: @id_token, subject_token_type: ID_TOKEN_TYPE, grant_type: GRANT_TYPE, audience: 'https://api.oase.app')
    params = {
      grant_type: grant_type,
      subject_token: subject_token,
      subject_token_type: subject_token_type
    }
    params[:audience] = audience unless audience.nil?

    headers = {}
    headers['DPoP'] = dpop if dpop

    post '/oauth2/token', params: params, headers: headers
  end

  def dpop_proof(htm: 'POST', htu: TOKEN_URL, iat: Time.now.to_i, jti: SecureRandom.uuid)
    JWT.encode(
      { htm: htm, htu: htu, iat: iat, jti: jti },
      @device_key,
      'ES256',
      typ: 'dpop+jwt',
      jwk: @device_jwk
    )
  end
end
