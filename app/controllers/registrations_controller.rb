class RegistrationsController < ApplicationController
  layout 'authentication'

  helper_method :mockup_mail

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
    email = registration_configuration[:email]
    @email_validator = EmailInquire.validate(email)

    bypass_email_check = email == params[:email_validation_shown_for]

    if @email_validator.valid? || bypass_email_check
      if ::Authentication::Services::Authenticate::Existing.known?(email)
        redirect_to verify_password_path(registration_configuration)
      else
        code = EmailVerificationCode.active_for_cleartext(email)
        if code
          redirect_to verify_email_registrations_path(registration_configuration)
        else
          redirect_to verify_human_registrations_path(registration_configuration)
        end
      end
    else
      render action: :new
    end
  end

  def verify_human
    return redirect_to confirm_path(login_configuration) if logged_in?
    return unless request.post?

    pass_turnstile!

    # Prepare the email for verification
    email_verifier.generate_and_send_verification_code!

    # Redirect to email verification
    flash[:slide_class] = 'a-slide-in-from-right'
    redirect_to verify_email_registrations_path(registration_configuration)
  rescue TurnstileConcern::NotPassedError
    render action: :verify_human
  rescue Net::SMTPFatalError => e
    @smtp_error = e
    render action: :new
  rescue Net::SMTPSyntaxError => e
    @smtp_error = e
    render action: :new
  rescue Net::SMTPServerBusy => e
    @smtp_error = e
    render action: :new
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    @smtp_error = e
    render action: :new
  end

  def verify_email
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
    elsif email_verifier.can_resend?
      # If the code is invalid, we send the mail, with a new code
      email_verifier.generate_and_send_verification_code!(old_code: @code.code)
      @code = email_verifier.verifier
      flash.now[:resent_code] = true
      render action: :verify_email
    else
      flash.now[:error] = I18n.t('too_many_codes_sent')
      render action: :verify_email
    end
  end

  def magic
    payload = MagicLink.redeem(params[:token])

    if payload.nil?
      flash[:error] = I18n.t('magic_link_invalid')
      return redirect_to login_path
    end

    configuration = payload.slice('email', 'client_id', 'redirect_uri', 'nonce', 'redirect_to', 'prompt')

    code = EmailVerificationCode.active_for_cleartext(payload['email'])

    if code.nil?
      # The code has expired or registration already finished. The payload
      # decrypted, so we can at least restore the flow with the e-mail
      # prefilled and the relying-party context intact.
      flash[:error] = I18n.t('magic_link_invalid')
      return redirect_to login_path(configuration)
    end

    if code.code.upcase != payload['code'].to_s.upcase
      # A newer code has been issued since this mail was sent.
      flash[:error] = I18n.t('magic_link_superseded')
      return redirect_to verify_email_registrations_path(configuration)
    end

    flash[:slide_class] = 'a-slide-in-from-right'
    redirect_to create_password_registrations_path(configuration.merge('email_verification_code' => code.code))
  end

  def create_password
    return redirect_to confirm_path(login_configuration) if logged_in?
    return unless request.post?
    return flash[:password_error] = 'blank' unless params[:password].strip.present?
    return flash[:password_error] = 'not_matching' unless params[:password] == params[:password_confirmation]
    return handle_stale_verification_code unless verify_email_verification_code!

    ActiveRecord::Base.transaction do
      email_verifier.reset!

      # Now we can register the user
      @auth_request = ::Authentication::Services::Authenticate.new params.permit(:email, :password)
      @auth_request.email_verified_at = Time.zone.now
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
      relying_party: relying_party,
      login_configuration: login_configuration.to_h
    )
  end

  # The verify_email page shows the mail it is waiting for — this builds
  # the ACTUAL mail (same templates, subject and sender as the delivered
  # one), just with the code masked to its first character and a dummy
  # link token. Never delivered, only rendered.
  def mockup_mail
    code = email_verifier.verifier.code
    EmailVerificationMailer.with(
      email: registration_configuration[:email],
      code: code.first + '•' * (code.length - 1),
      relying_party_name: relying_party&.name,
      magic_link_token: 'mockup'
    ).verify_email
  end

  # The code in the params no longer matches — most likely a stale magic
  # link, or the code was regenerated in another tab. Send a fresh code
  # and let the user pick up from the verify_email step.
  def handle_stale_verification_code
    current_code = email_verifier.verifier
    if current_code.nil?
      # nothing to resend against — verify_email will route onwards
    elsif email_verifier.can_resend?
      email_verifier.generate_and_send_verification_code!(old_code: current_code.code)
      flash[:resent_code] = true
    else
      flash[:error] = I18n.t('too_many_codes_sent')
    end
    redirect_to verify_email_registrations_path(registration_configuration(:email_verification_code))
  end
end
