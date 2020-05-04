class AuthenticationController < ApplicationController

  def login
    reset_session

    @auth_request = ::Authentication::Services::Authenticate.new email: flash[:email]
    if personal_data
      redirect_to confirm_path(login_configuration)
    end
  end

  def confirm
    if personal_data.blank?
      redirect_to login_path(login_configuration)
    else
      if relying_party.blank?
        redirect_to dashboard_path
      end
    end
  end

  def relogin
    logout
  end

  def logout
    do_logout!
    redirect_to login_path(login_configuration)
  end

  def go_to
    if relying_party.present?
      id_token = Authentication::Services::GetIdToken.new(
        user_id: current_user_id, 
        relying_party_id: relying_party.id,
        vault_key: current_vault_key,
        nonce: login_configuration[:nonce]
      ).id_token

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
        cookies.encrypted.permanent[:vault_key] = @auth_request.vault_key
        cookies.encrypted.permanent[:email] = params[:email]
      end
      session[:user_id]  = @auth_request.user_id
      session[:vault_key] = @auth_request.vault_key
      session[:email] = params[:email]

      redirect_to confirm_path(login_configuration)
    else
      flash.now[:remember_me] = params[:remember_me]
      if @auth_request.errors.include?(:email)
        flash.now[:email_message] = @auth_request.errors.full_messages_for(:email).first
      else
        flash.now[:password_message] = @auth_request.errors.full_messages_for(:password).first
      end
      flash.now[:email] = @auth_request.email
      render action: 'login'
    end
  rescue Authentication::Password::NotMatching
    flash.now[:remember_me] = params[:remember_me]
    flash.now[:email] = @auth_request.email
    flash.now[:password_message] = t('.password_not_correct')
    render action: 'login'
  end

  def login_configuration
    params.permit(:client_id, :redirect_uri, :nonce)
  end
  helper_method :login_configuration

  private

end
