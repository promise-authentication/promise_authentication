module AuthenticatedConcern
  extend ActiveSupport::Concern

  included do
    helper_method :logged_in?
    helper_method :current_user
    helper_method :login_configuration
    helper_method :registration_configuration
  end

  def require_signed_id
    redirect_to login_path(redirect_to: url_for) unless logged_in?
  end

  def logged_in?
    current_user_email.present? &&
      current_user_id.present? &&
      current_user_vault_key.present? &&
      current_user_personal_data.present?
  end

  def current_user
    @current_user ||= OpenStruct.new({
                                       email: current_user_email,
                                       id: current_user_id,
                                       data: current_user_personal_data,
                                       vault_key: current_user_vault_key,
                                       unique: OpenStruct.new({
                                                                color: unique_color,
                                                                character: unique_character
                                                              })
                                     })
  end

  def current_user_personal_data
    return nil unless current_user_vault_key.present?

    @personal_data ||= lambda do
      Authentication::Vault.personal_data(current_user_id, current_user_vault_key)
    end.call
  end

  def current_user_email
    cookies.encrypted[:email] || session[:email]
  end

  def current_user_id
    cookies.encrypted[:user_id] || session[:user_id]
  end

  def current_user_vault_key
    base64 = cookies.encrypted[:vault_key_base64] || session[:vault_key_base64]
    Base64.strict_decode64(base64) if base64
  end

  def something_unique
    return nil unless logged_in?

    @something_unique ||= ::Authentication::SomethingUnique.find(current_user_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def unique_color
    something_unique&.color
  end

  def unique_character
    something_unique&.character
  end

  def do_sign_in(auth_request)
    if params[:remember_me].present?
      cookies.encrypted.permanent[:user_id] = auth_request.user_id
      cookies.encrypted.permanent[:vault_key_base64] = auth_request.vault_key_base64
      cookies.encrypted.permanent[:email] = params[:email]
    end
    session[:user_id] = auth_request.user_id
    session[:vault_key_base64] = auth_request.vault_key_base64
    session[:email] = params[:email]
  end

  def update_email_in_session_and_cookies(new_email)
    cookies.encrypted[:email] = new_email if cookies.encrypted[:email].present?
    return unless session[:email].present?

    session[:email] = new_email
  end

  def do_logout!
    reset_session
    cookies.delete :user_id
    cookies.delete :vault_key_base64
    cookies.delete :email
  end

  def login_configuration
    params.permit(:client_id, :redirect_uri, :nonce, :redirect_to, :prompt)
  end

  def registration_configuration(*args)
    list = %i[email email_verification_code remember_me].reject { |item| args.include?(item) }
    login_configuration.merge params.permit(list)
  end
end
