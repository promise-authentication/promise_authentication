class PasswordsController < ApplicationController
  before_action :require_signed_id, only: :create

  layout 'authentication'

  def create
    change_request = ::Authentication::Services::ChangePassword.new params.permit(:current_password, :new_password)
    change_request.user_id = current_user.id

    if change_request.valid?
      change_request.call

      cookies.encrypted.permanent[:vault_key_base64] = change_request.vault_key_base64

      redirect_to login_path
    else
      @current_password_message = if change_request.errors.include?(:current_password)
                                    change_request.errors.full_messages_for(:current_password).first
                                  else
                                    I18n.t('fill_both')
                                  end
    end
  rescue Authentication::Password::NotMatching
    @current_password_message = I18n.t('password_not_matching')
    render action: 'edit'
  end

  def recover
    pass_turnstile!

    email = params.fetch(:email)
    if email.blank?
      flash[:error] = I18n.t('fill_email')
      return render action: 'new'
    end

    args = params.permit(:email).merge({
                                         locale: I18n.locale,
                                         relying_party: relying_party
                                       })

    ::Authentication::Services::SendRecoveryMail.new(args).call

    redirect_to wait_password_path(login_configuration)
  rescue TurnstileConcern::NotPassedError
    flash[:error] = I18n.t('fill_email')
    return render action: 'new'
  end
end
