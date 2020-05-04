class RecoveriesController < ApplicationController
  layout 'authentication'
  before_action :ensure_recoverable

  def show
  end

  def update
    if params[:new_password].blank?
      render action: :show
    else
      Authentication::Services::RecoverySetPassword.new(
        new_password: params[:new_password],
        user_id: params[:id],
        secret_key_base64: params[:key_id]
      ).call!
      redirect_to login_path
    end
  rescue RbNaCl::CryptoError
    redirect_to login_path
  end

  private

  def ensure_recoverable
    recovery = Authentication::VaultKeysForRecovery.find(params[:id])
    unless recovery&.recoverable_vault_key_cipher_base64.present?
      redirect_to root_path
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end

