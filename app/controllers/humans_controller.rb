class HumansController < ApplicationController

  def login
    @auth_request = ::Authentication::Request.new email: flash[:email]
  end

  def authenticate
    @auth_request = ::Authentication::Request.new params.permit(:email, :password)

    if @auth_request.valid?
      raise

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
