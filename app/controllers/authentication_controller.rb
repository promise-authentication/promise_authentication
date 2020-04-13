class AuthenticationController < ApplicationController

  def login
    @auth_request = ::Authentication::Services::Authenticate.new email: flash[:email]
    if personal_data
      redirect_to confirm_path(login_configuration)
    end
  end

  def confirm
    if relying_party.blank?
      redirect_to dashboard_path
    end
  end

  def relogin
    cookies.delete :user_id
    cookies.delete :vault_key
    redirect_to login_path(login_configuration)
  end

  def logout
    cookies.delete :user_id
    cookies.delete :vault_key
    redirect_to login_path(login_configuration)
  end

  def go_to
    if relying_party.present?
      id_token = Authentication::Services::GetIdToken.new(
        user_id: current_user_id, 
        relying_party_id: relying_party.id,
        vault_key: current_vault_key
      ).id_token

      redirect_to "https://#{relying_party.id}/authenticate?id_token=#{id_token}"
    else
      redirect_to dashboard_path
    end
  end


  def authenticate
    @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :password)

    if @auth_request.valid?

      user_id, salt = @auth_request.user_id_and_salt
      vault_key = Authentication::Vault.key_from(@auth_request.password, salt)

      cookies.encrypted.permanent[:user_id] = user_id
      cookies.encrypted.permanent[:vault_key] = vault_key

      redirect_to confirm_path(login_configuration)
    else
      if @auth_request.errors.include?(:email)
        flash[:email_message] = @auth_request.errors.full_messages_for(:email).first
      else
        flash[:password_message] = @auth_request.errors.full_messages_for(:password).first
      end
      flash[:email] = @auth_request.email
      redirect_to login_path(login_configuration)
    end
  rescue Authentication::Password::NotMatching
    flash[:email] = @auth_request.email
    flash[:password_message] = 'Password not correct. Please try again'
    redirect_to login_path(login_configuration)
  end

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:aud])
  end
  helper_method :relying_party

  def login_configuration
    params.permit(:aud, :redirect_url, :mfa)
  end
  helper_method :login_configuration

  private

end
