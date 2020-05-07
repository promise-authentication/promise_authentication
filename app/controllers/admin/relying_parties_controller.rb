class Admin::RelyingPartiesController < ApplicationController
  before_action :authenticate

  def show
  end

  private

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:id])
  end
  helper_method :relying_party
end
