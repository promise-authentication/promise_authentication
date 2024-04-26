class AuthenticationController < ApplicationController
  before_action :require_signed_id, except: %i[login authenticate logout]

  def login
    if(logged_in? && (login_configuration[:prompt] == 'login'))
      do_logout!
    end

    old_flash = flash.to_h
    reset_session
    old_flash.each do |k, v|
      flash.now[k] = v
    end

    @auth_request = ::Authentication::Services::Authenticate.new email: flash[:email]
    return unless logged_in?

    redirect_to confirm_path(login_configuration)
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

  def do_sign_in
    if params[:remember_me].present?
      cookies.encrypted.permanent[:user_id] = @auth_request.user_id
      cookies.encrypted.permanent[:vault_key_base64] = @auth_request.vault_key_base64
      cookies.encrypted.permanent[:email] = params[:email]
    end
    session[:user_id] = @auth_request.user_id
    session[:vault_key_base64] = @auth_request.vault_key_base64
    session[:email] = params[:email]
  end

  def authenticate
    do_logout!

    @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :password)
    @auth_request.relying_party_id = relying_party&.id

    if @auth_request.valid?
      @auth_request.existing! || @auth_request.register!(email_confirmation: params[:email_confirmation])
      do_sign_in

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
  rescue Authentication::Services::Authenticate::EmailConfirmationError
    @remember_me = params[:remember_me]
    @email = params[:email]
    @password = params[:password]
    flash.now[:slide_class] = 'a-slide-in-from-right'
    flash.now[:email_confirmation_message] = t('.confirmation_not_matching') if params[:email_confirmation].present?
    render action: :confirm_email
  rescue Authentication::Password::NotMatching
    flash[:remember_me] = params[:remember_me]
    flash[:email] = @auth_request.email
    flash[:password_message] = t('.password_not_correct')
    redirect_to login_path(login_configuration)
  end
end
