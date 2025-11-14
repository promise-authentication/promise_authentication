class AuthenticationController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:authenticate]
  before_action :require_signed_id, except: %i[verify_password authenticate logout]

  def password
    @auth_request = ::Authentication::Services::Authenticate.new email: flash[:email]
  end

  def confirm
    return unless relying_party.blank?

    redirect_to params[:redirect_to] || dashboard_path
  end

  def relogin
    do_logout!
    flash[:slide_class] = 'a-slide-in-from-left'
    redirect_to login_path(login_configuration)
  end

  def logout
    do_logout!
    redirect_to params[:redirect_uri] || login_path(login_configuration)
  end

  def go_to
    if relying_party.present?
      id_token = Authentication::Services::GetIdToken.new(
        user_id: current_user.id,
        relying_party_id: relying_party.id,
        vault_key: current_user.vault_key,
        nonce: login_configuration[:nonce]
      ).id_token

      Statistics::SignInEvent.create(
        token_id: id_token.jti,
        user_id: id_token.sub,
        relying_party_id: id_token.aud
      )

      redirect_to relying_party.redirect_uri(
        id_token: id_token,
        login_configuration: login_configuration
      )

      reset_session
    else
      redirect_to dashboard_path
    end
  end

  def authenticate
    do_logout!

    @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :password)
    @auth_request.relying_party_id = relying_party&.id

    if @auth_request.valid?
      @auth_request.existing!
      do_sign_in(@auth_request)

      go_to
    else
      flash[:remember_me] = params[:remember_me]
      if @auth_request.errors.include?(:email)
        flash[:email_message] = @auth_request.errors.full_messages_for(:email).first
      else
        flash[:password_message] = @auth_request.errors.full_messages_for(:password).first
      end
      redirect_to verify_password_path(registration_configuration)
    end
  rescue Authentication::Password::NotMatching
    flash[:password_message] = t('.password_not_correct')
    redirect_to verify_password_path(registration_configuration)
  end
end
