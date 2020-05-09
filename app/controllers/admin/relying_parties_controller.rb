class Admin::RelyingPartiesController < ApplicationController
  # before_action :authenticate

  layout 'about'

  def show
  end

  def index
    if params[:id]
      redirect_to admin_relying_party_path(id: params[:id].presence || 'example.com')
    end
  end

  private

  def admin_relying_party
    @admin_relying_party ||= ::Authentication::RelyingParty.find(params[:id])
  end
  helper_method :admin_relying_party
end
