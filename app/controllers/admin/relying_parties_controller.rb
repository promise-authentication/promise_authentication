class Admin::RelyingPartiesController < ApplicationController
  # before_action :authenticate

  layout 'about'

  def show
  end

  def index
    if params[:id]
      redirect_to admin_relying_party_path(id: params[:id])
    end
  end

  private

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:id])
  end
  helper_method :relying_party
end
