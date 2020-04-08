class HumansController < ApplicationController

  def login
    @auth_request = ::Authentication::Services::Authenticate.new email: flash[:email]
  end

  def authenticate
    @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :password)

    if @auth_request.valid?

      user_id, salt = @auth_request.user_id_and_salt

      session[:user_id] = user_id
      session[:vault_key] = Authentication::Vault.key_from(@auth_request.password, salt)
      redirect_to root_path

    else
      if @auth_request.errors.include?(:email)
        flash[:email_message] = @auth_request.errors.full_messages_for(:email).first
      else
        flash[:password_message] = @auth_request.errors.full_messages_for(:password).first
      end
      flash[:email] = @auth_request.email
      redirect_to login_path
    end
  end

end
