class EmailsController < ApplicationController
  before_action :require_signed_id, only: %i[create edit]

  layout 'authentication'

  def verify
    @code = identifier_verifier&.verifier

    if @code.nil?
      return redirect_to(confirm_path(login_configuration)) if logged_in?

      return redirect_to login_path(registration_configuration)
    end
  end

  def create
    if params[:email_verification_code].blank?
      if to_identifier.nil? || to_identifier.value.blank?
        redirect_to edit_email_path
      else
        identifier_verifier.generate_and_send_verification_code!
        redirect_to verify_email_path(registration_configuration)
      end
    else
      change_request = ::Authentication::Services::ChangeIdentifier.new(
        from_identifier: current_identifier,
        to_identifier: to_identifier,
        user_id: current_user.id,
        confirmation_code: params[:email_verification_code]
      )

      if change_request.valid?
        if change_request.call
          flash[:info] = I18n.t('email_changed')
          update_identifier_in_session_and_cookies(to_identifier)
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
  rescue Authentication::Email::AlreadyClaimed, Authentication::Phone::AlreadyClaimed
    flash[:error] = I18n.t('email_already_claimed')
    redirect_to dashboard_path
  end

  private

  def current_identifier
    Authentication::Identifier.parse(current_user.identifier, type: current_user.identifier_type)
  end

  def to_identifier
    signup_identifier
  end

  def identifier_verifier
    return nil if to_identifier.nil?

    @identifier_verifier ||=
      if to_identifier.phone?
        Authentication::Services::PrepareIdentifierForValidation.new(
          identifier: to_identifier,
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
