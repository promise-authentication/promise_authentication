class EmailsController < ApplicationController
  before_action :require_signed_id, only: %i[create edit]

  layout 'authentication'

  def verify
    @code = email_verifier.verifier

    if @code.nil?
      return redirect_to(confirm_path(login_configuration)) if logged_in?

      return redirect_to login_path(registration_configuration)
    end
    return unless request.post?

    if verify_email_verification_code!
      # If the code is valid, redirect to the passwords page
      flash[:slide_class] = 'a-slide-in-from-right'
      redirect_to create_password_registrations_path(registration_configuration)
    else
      # If the code is invalid, we send the mail, with a new code
      email_verifier.generate_and_send_verification_code!(old_code: @code.code)
      @code = email_verifier.verifier
      flash.now[:resent_code] = true
      render action: :verify_email
    end
  end

  def create
    if params[:email_verification_code].blank?
      @email_verifier ||= Authentication::Services::PrepareEmailForValidation.new(
        email: params[:email]
      )
      @email_verifier.generate_and_send_verification_code!
      redirect_to verify_email_path(registration_configuration)
    else
      change_request = ::Authentication::Services::ChangeEmail.new(
        from_email: current_user.email,
        to_email: registration_configuration[:email]
      )
      change_request.user_id = current_user.id
      change_request.confirmation_code = params[:email_verification_code]

      if change_request.valid?
        if change_request.call
          flash[:info] = I18n.t('email_changed')
          update_email_in_session_and_cookies(registration_configuration[:email])
          redirect_to dashboard_path
        elsif change_request.errors[:confirmation_code].present?
          flash[:error] = I18n.t('invalid_email_verification_code')
          redirect_to verify_email_path(registration_configuration)
        else
          flash[:error] = I18n.t('error_changing_email')
          redirect_to dashboard_path
        end
      else
        flash[:error] = I18n.t('error_changing_email')
        redirect_to dashboard_path
      end
    end
  rescue Authentication::Email::AlreadyClaimed
    flash[:error] = I18n.t('email_already_claimed')
    redirect_to dashboard_path
  end

  def verify_email_verification_code!
    email_verifier.verify!(registration_configuration[:email_verification_code])
  end

  def email_verifier
    @email_verifier ||= Authentication::Services::PrepareEmailForValidation.new(
      email: registration_configuration[:email],
      relying_party: relying_party
    )
  end
end
