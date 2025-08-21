class EmailsController < ApplicationController
  before_action :require_signed_id, only: :create

  layout 'authentication'

  def create
    if params[:confirmation_code].blank?
      @email_verifier ||= Authentication::Services::PrepareEmailForValidation.new(
        email: params[:new_email]
      )
      @email_verifier.generate_and_send_verification_code!
      render action: :confirm
    else
      change_request = ::Authentication::Services::ChangeEmail.new params.permit(:new_email)
      change_request.user_id = current_user.id
      change_request.confirmation_code = params[:confirmation_code]

      if change_request.valid?
        change_request.call

        redirect_to login_path
      else
        @current_email_message = if change_request.errors.include?(:current_password)
                                   change_request.errors.full_messages_for(:current_password).first
                                 else
                                   I18n.t('fill_both')
                                 end
      end
    end
  end
end
