class ApplicationController < ActionController::Base
  around_action :switch_locale

  protect_from_forgery with: :reset_session

  private

  def switch_locale(&action)
    begin
      I18n.with_locale(locale, &action)
    rescue I18n::InvalidLocale
      I18n.with_locale(I18n.default_locale, &action)
    end
  end

  def locale
    locale_from_cookie || extract_locale_from_accept_language_header || relying_party&.locale || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    request_locale = request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first
  end

  def locale_from_cookie
    if params[:locale]
      cookies.permanent[:locale] = params[:locale]
    end

    cookies[:locale]
  end

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:client_id])
  end
  helper_method :relying_party
  
  def authenticate
    redirect_to login_path if personal_data.nil?
  end

  def something_unique
    return nil unless current_user_id

    @something_unique ||= ::Authentication::SomethingUnique.find(current_user_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def unique_color
    something_unique&.color
  end
  helper_method :unique_color

  def unique_character
    something_unique&.character
  end
  helper_method :unique_character

  def personal_data
    return nil if current_user_id.blank?

    @personal_data ||= -> do
      Authentication::Vault.personal_data(current_user_id, current_vault_key)
    end.call
  end
  helper_method :personal_data

  def email
    cookies.encrypted[:email] || session[:email]
  end
  helper_method :email

  def current_user_id
    cookies.encrypted[:user_id] || session[:user_id]
  end

  def current_vault_key
    cookies.encrypted[:vault_key] || session[:vault_key]
  end

  def do_logout!
    reset_session
    cookies.delete :user_id
    cookies.delete :vault_key
    cookies.delete :email
  end
end
