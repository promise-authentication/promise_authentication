class ApplicationController < ActionController::Base

  private

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
