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

    identifier = signup_identifier
    # E-mail recovery stays lenient (an unknown address just gets the "unknown"
    # mail), but an invalid phone number would dead-end on the SMS code screen
    # with no code ever sent, so reject it up front.
    if identifier.nil? || (identifier.phone? && !identifier.valid?)
      flash[:error] = I18n.t('fill_email')
      return render action: 'new'
    end

    ::Authentication::Services::SendRecovery.new(
      identifier: identifier,
      locale: I18n.locale,
      relying_party: relying_party
    ).call

    if identifier.phone?
      session[:recovery_identifier_value] = identifier.value
      session[:recovery_identifier_type] = identifier.type.to_s
      redirect_to recover_code_password_path(login_configuration)
    else
      redirect_to wait_password_path(login_configuration)
    end
  rescue TurnstileConcern::NotPassedError
    flash[:error] = I18n.t('fill_email')
    render action: 'new'
  end

  # Phone recovery: the user enters the SMS code, which unlocks the
  # server-side recovery token.
  def recover_code
    @identifier = recovery_identifier
    return redirect_to new_password_path if @identifier.nil?
    return unless request.post?

    verifier = Authentication::Services::PrepareIdentifierForValidation.new(identifier: @identifier)

    if verifier.verify!(params[:verification_code])
      user_id = Authentication::HashedIdentifier.user_id_for(@identifier)
      token = Authentication::RecoveryToken.active.where(user_id: user_id).last

      if token
        verifier.reset!
        session[:recovery_token] = token.token
        redirect_to reset_password_path(login_configuration)
      else
        redirect_to new_password_path
      end
    else
      flash.now[:error] = I18n.t('invalid_email_verification_code')
      render action: :recover_code
    end
  end

  # Phone recovery: set the new password using the session-held token.
  def reset
    return redirect_to new_password_path if session[:recovery_token].blank?
    return unless request.post?

    if params[:new_password].blank?
      flash.now[:error] = I18n.t('fill_both')
      return render action: :reset
    end

    Authentication::Services::RecoverySetPassword.new(
      new_password: params[:new_password],
      token: session[:recovery_token]
    ).call!

    clear_recovery_session
    redirect_to login_path
  rescue RbNaCl::CryptoError
    redirect_to login_path
  end

  private

  def recovery_identifier
    value = session[:recovery_identifier_value]
    type = session[:recovery_identifier_type]
    return nil if value.blank? || type.blank?

    Authentication::Identifier.parse(value, type: type)
  end

  def clear_recovery_session
    session.delete(:recovery_token)
    session.delete(:recovery_identifier_value)
    session.delete(:recovery_identifier_type)
  end
end
