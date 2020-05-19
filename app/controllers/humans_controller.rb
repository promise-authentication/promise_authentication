class HumansController < ApplicationController
  before_action :require_signed_id

  def show
    @relying_parties = current_user.data.ids.keys.map do |key|
      Authentication::RelyingParty.find(key)
    end
    render layout: 'authentication'
  end

  def uniq
    render layout: 'application'
  end
end
