class PasswordsController < ApplicationController
  before_action :authenticate

  layout 'authentication'

  def create
    change_request = ::Authentication::Services::ChangePassword.new params.permit(:current_password, :new_password)
    change_request.user_id = current_user_id

    if change_request.valid?
      vault_key = change_request.new_key

      cookies.encrypted.permanent[:vault_key] = vault_key

      redirect_to login_path
    else
      if change_request.errors.include?(:current_password)
        @current_password_message = change_request.errors.full_messages_for(:current_password).first
      else
        @current_password_message = I18n.t('fill_both')
      end

      render action: 'show'
    end
  rescue Authentication::Password::NotMatching
    @current_password_message = I18n.t('password_not_matching')
    render action: 'show'
  end

end
