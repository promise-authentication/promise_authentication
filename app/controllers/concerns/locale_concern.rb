module LocaleConcern
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

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
end
