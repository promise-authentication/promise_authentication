class RecoveriesController < ApplicationController
  layout 'authentication'
  before_action :ensure_recoverable

  def index
  end

  def create
    if params[:new_password].blank?
      render action: :index
    else
      Authentication::Services::RecoverySetPassword.new(
        new_password: params[:new_password],
        token: params[:token_id]
      ).call!
      redirect_to login_path
    end
  rescue RbNaCl::CryptoError
    redirect_to login_path
  end

  private

  def ensure_recoverable
    recovery = Authentication::RecoveryToken.find_by_token(params[:token_id])
    unless recovery.present?
      redirect_to root_path
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
