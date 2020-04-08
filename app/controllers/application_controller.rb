class ApplicationController < ActionController::Base

  private

  def personal_data
    return nil if session[:user_id].blank?

    @personal_data ||= -> do
      encrypted = Authentication::VaultContent.find(session[:user_id]).encrypted_personal_data
      decrypted = Authentication::Vault.new(key: session[:vault_key]).decrypt encrypted
      Authentication::PersonalData.new(
        decrypted
      )
    end.call
  end
  helper_method :personal_data
end
