class AuthenticationController < ApplicationController
  before_action :require_signed_id, except: [:login, :authenticate, :logout]

  def login
    old_flash = flash.to_h
    reset_session
    old_flash.each do |k, v|
      flash.now[k] = v
    end

    @auth_request = ::Authentication::Services::Authenticate.new email: flash[:email]
    if logged_in?
      redirect_to confirm_path(login_configuration)
    end
  end

  def confirm
    if relying_party.blank?
      if params[:redirect_to]
        redirect_to params[:redirect_to]
      else
        redirect_to dashboard_path
      end
    end
  end

  def relogin
    do_logout!
    flash[:slide_class] = 'a-slide-in-from-left'
    redirect_to login_path(login_configuration)
  end

  def logout
    do_logout!
    if params[:redirect_uri]
      redirect_to params[:redirect_uri]
    else
      redirect_to login_path(login_configuration)
    end
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
        relying_party_id: id_token.aud,
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
      @auth_request.call!

      if params[:remember_me]
        cookies.encrypted.permanent[:user_id]  = @auth_request.user_id
        cookies.encrypted.permanent[:vault_key_base64] = @auth_request.vault_key_base64
        cookies.encrypted.permanent[:email] = params[:email]
      end
      session[:user_id]  = @auth_request.user_id
      session[:vault_key_base64] = @auth_request.vault_key_base64
      session[:email] = params[:email]

      flash[:slide_class] = 'a-slide-in-from-right'
      redirect_to confirm_path(login_configuration)
    else
      flash[:remember_me] = params[:remember_me]
      if @auth_request.errors.include?(:email)
        flash[:email_message] = @auth_request.errors.full_messages_for(:email).first
      else
        flash[:password_message] = @auth_request.errors.full_messages_for(:password).first
      end
      flash[:email] = @auth_request.email
      redirect_to login_path(login_configuration)
    end
  rescue Authentication::Password::NotMatching
    flash[:remember_me] = params[:remember_me]
    flash[:email] = @auth_request.email
    flash[:password_message] = t('.password_not_correct')
    redirect_to login_path(login_configuration)
  end
end
