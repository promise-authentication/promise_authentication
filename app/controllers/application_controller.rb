class ApplicationController < ActionController::Base
  around_action :switch_locale

  private

  def switch_locale(&action)
    begin
      I18n.with_locale(locale, &action)
    rescue I18n::InvalidLocale
      I18n.with_locale(I18n.default_locale, &action)
    end
  end

  def locale
    user_settings&.locale || params[:locale] || relying_party&.locale || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    request_locale = request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first
  end

  def user_settings
    nil
  end

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:aud])
  end
  helper_method :relying_party
  
  def authenticate
    redirect_to logout_path if personal_data.nil?
  end

  def personal_data
    return nil if current_user_id.blank?

    @personal_data ||= -> do
      Authentication::Vault.personal_data(current_user_id, current_vault_key)
    end.call
  end
  helper_method :personal_data

  def current_user_id
    cookies.encrypted[:user_id]
  end

  def current_vault_key
    cookies.encrypted[:vault_key]
  end
end
