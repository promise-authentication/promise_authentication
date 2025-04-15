class RegistrationsController < ApplicationController
  layout 'authentication'

  def new
    do_logout! if logged_in? && (login_configuration[:prompt] == 'login')

    old_flash = flash.to_h
    reset_session
    old_flash.each do |k, v|
      flash.now[k] = v
    end

    return unless logged_in?

    redirect_to confirm_path(login_configuration)
  end

  def create
    flash[:slide_class] = 'a-slide-in-from-right'

    if ::Authentication::Services::Authenticate::Existing.known?(registration_configuration[:email])
      redirect_to verify_password_path(registration_configuration)
    else
      redirect_to verify_human_registrations_path(registration_configuration)
    end
  end

  def verify_human
    return unless request.post?

    pass_turnstile!

    # Prepare the email for verification
    email_verifier.generate_and_send_verification_code!

    # Redirect to email verification
    flash[:slide_class] = 'a-slide-in-from-right'
    redirect_to verify_email_registrations_path(registration_configuration)
  rescue TurnstileConcern::NotPassedError
    render action: :verify_human
  end

  def verify_email
    @code = email_verifier.verifier

    return unless request.post?

    if verify_email_verification_code!
      # If the code is valid, redirect to the passwords page
      flash[:slide_class] = 'a-slide-in-from-right'
      redirect_to create_password_registrations_path(registration_configuration)
    else
      # If the code is invalid, we send the mail, with a new code
      email_verifier.generate_and_send_verification_code!
      @code = email_verifier.verifier
      flash.now[:resent_code] = true
      render action: :verify_email
    end
  end

  def create_password
    return unless request.post?
    return unless params[:password].strip.present?
    return unless verify_email_verification_code!

    ActiveRecord::Base.transaction do
      email_verifier.reset!

      # Now we can register the user
      @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :password)
      @auth_request.relying_party_id = relying_party&.id

      return unless @auth_request.valid?

      @auth_request.register!

      do_sign_in(@auth_request)

      flash[:slide_class] = 'a-slide-in-from-right'
      redirect_to confirm_path(login_configuration)
    end
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
