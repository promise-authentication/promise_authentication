module AuthenticatedConcern
  extend ActiveSupport::Concern

  included do
    helper_method :logged_in?
    helper_method :current_user
  end

  def authenticate
    redirect_to login_path(redirect_to: url_for) unless logged_in?
  end

  def logged_in?
    current_user_email.present? &&
      current_user_id.present? &&
      current_user_vault_key.present?
  end

  def current_user
    @current_user ||= begin
                        OpenStruct.new({
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
  end

  def current_user_personal_data
    return nil unless logged_in?

    @personal_data ||= -> do
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
    cookies.encrypted[:vault_key] || session[:vault_key]
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

  def do_logout!
    reset_session
    cookies.delete :user_id
    cookies.delete :vault_key
    cookies.delete :email
  end
end
