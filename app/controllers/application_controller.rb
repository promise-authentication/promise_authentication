class ApplicationController < ActionController::Base

  private

  def personal_data
    return nil if session[:user_id].blank?

    @personal_data ||= -> do
      Authentication::Vault.personal_data(session[:user_id], session[:vault_key])
    end.call
  end
  helper_method :personal_data
end
