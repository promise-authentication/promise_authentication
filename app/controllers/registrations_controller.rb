class RegistrationsController < ApplicationController
  layout 'authentication'

  SMTP_ERRORS = [
    Net::SMTPFatalError,
    Net::SMTPSyntaxError,
    Net::SMTPServerBusy,
    Net::OpenTimeout,
    Net::ReadTimeout
  ].freeze

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

    if signup_identifier&.phone?
      create_with_phone
    else
      create_with_email
    end
  end

  def verify_human
    return redirect_to confirm_path(login_configuration) if logged_in?
    return unless request.post?

    pass_turnstile!

    # Generate and send the verification code (by e-mail or SMS).
    identifier_verifier.generate_and_send_verification_code!

    flash[:slide_class] = 'a-slide-in-from-right'
    redirect_to verify_email_registrations_path(registration_configuration)
  rescue TurnstileConcern::NotPassedError
    render action: :verify_human
  rescue *SMTP_ERRORS => e
    @smtp_error = e
    render action: :new
  end

  def verify_email
    @code = identifier_verifier.verifier

    if @code.nil?
      return redirect_to(confirm_path(login_configuration)) if logged_in?

      return redirect_to login_path(registration_configuration)
    end
    return unless request.post?

    if verify_verification_code!
      # If the code is valid, redirect to the passwords page
      flash[:slide_class] = 'a-slide-in-from-right'
      redirect_to create_password_registrations_path(registration_configuration)
    else
      # If the code is invalid, we send a new one
      identifier_verifier.generate_and_send_verification_code!(old_code: @code.code)
      @code = identifier_verifier.verifier
      flash.now[:resent_code] = true
      render action: :verify_email
    end
  end

  def create_password
    return redirect_to confirm_path(login_configuration) if logged_in?
    return unless request.post?
    return flash[:password_error] = 'blank' unless params[:password].strip.present?
    return flash[:password_error] = 'not_matching' unless params[:password] == params[:password_confirmation]
    return unless verify_verification_code!

    ActiveRecord::Base.transaction do
      identifier_verifier.reset!

      # Now we can register the user
      @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :phone, :password)
      @auth_request.verified_at = Time.zone.now
      @auth_request.relying_party_id = relying_party&.id

      return unless @auth_request.valid?

      @auth_request.register!

      do_sign_in(@auth_request)

      flash[:slide_class] = 'a-slide-in-from-right'
      redirect_to confirm_path(login_configuration)
    end
  end

  private

  def create_with_email
    email = registration_configuration[:email]
    @email_validator = EmailInquire.validate(email)

    bypass_email_check = email == params[:email_validation_shown_for]

    if @email_validator.valid? || bypass_email_check
      route_after_identification(Authentication::Identifier.email(email))
    else
      render action: :new
    end
  end

  def create_with_phone
    if signup_identifier.valid?
      route_after_identification(signup_identifier)
    else
      @phone_invalid = true
      render action: :new
    end
  end

  def route_after_identification(identifier)
    if ::Authentication::Services::Authenticate::Existing.known?(identifier)
      redirect_to verify_password_path(registration_configuration)
    elsif VerificationCode.find_for(identifier)
      redirect_to verify_email_registrations_path(registration_configuration)
    else
      redirect_to verify_human_registrations_path(registration_configuration)
    end
  end

  def verify_verification_code!
    identifier_verifier.verify!(registration_configuration[:email_verification_code])
  end

  def identifier_verifier
    @identifier_verifier ||=
      if signup_identifier&.phone?
        Authentication::Services::PrepareIdentifierForValidation.new(
          identifier: signup_identifier,
          relying_party: relying_party
        )
      else
        Authentication::Services::PrepareEmailForValidation.new(
          email: registration_configuration[:email],
          relying_party: relying_party
        )
      end
  end
end
