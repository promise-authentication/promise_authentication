class HumansController < ApplicationController
  before_action :require_signed_id

  def show
    @ids = current_user.data.ids
    render layout: 'authentication'
  end

  def uniq
    render layout: 'application'
  end
end
