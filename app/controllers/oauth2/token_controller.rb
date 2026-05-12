class Oauth2::TokenController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:exchange]

  GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:token-exchange'.freeze
  ID_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:id_token'.freeze
  ACCESS_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:access_token'.freeze
  ISSUER = ENV.fetch('PROMISE_ISSUER', 'https://promiseauthentication.org').freeze
  ACCESS_TOKEN_TTL = 120

  def exchange
    return render_error('invalid_request', 'unsupported grant_type', status: :bad_request) unless params[:grant_type] == GRANT_TYPE
    return render_error('invalid_request', 'unsupported subject_token_type', status: :bad_request) unless params[:subject_token_type] == ID_TOKEN_TYPE
    return render_error('invalid_request', 'subject_token is required', status: :bad_request) if params[:subject_token].blank?
    return render_error('invalid_request', 'audience is required', status: :bad_request) if params[:audience].blank?

    proof = Dpop::Proof.verify!(
      request.headers['DPoP'],
      http_method: request.method,
      http_url: request.url
    )

    subject = Authentication::IdToken.parse(params[:subject_token])

    access_token = mint_access_token(sub: subject.sub, audience: params[:audience], jkt: proof.jkt)

    render json: {
      access_token: access_token,
      issued_token_type: ACCESS_TOKEN_TYPE,
      token_type: 'Bearer',
      expires_in: ACCESS_TOKEN_TTL
    }
  rescue Dpop::Proof::InvalidProof => e
    render_error('invalid_dpop_proof', e.message, status: :bad_request)
  rescue JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature
    render_error('invalid_grant', 'subject_token is not valid', status: :bad_request)
  end

  private

  def mint_access_token(sub:, audience:, jkt:)
    cert = Trust::Certificate.current
    kid = cert.public_key.to_jwk['kid']
    now = Time.now.to_i

    payload = {
      iss: ISSUER,
      sub: sub,
      aud: audience,
      iat: now,
      exp: now + ACCESS_TOKEN_TTL,
      jti: SecureRandom.uuid,
      cnf: { jkt: jkt }
    }

    JWT.encode(payload, cert.private_key, 'ES512', kid: kid)
  end

  def render_error(code, description, status:)
    render json: { error: code, error_description: description }, status: status
  end
end
