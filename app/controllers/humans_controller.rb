class HumansController < ApplicationController

  def show
    if personal_data.present?
      @relying_parties = personal_data.ids.keys.map do |key|
        Authentication::RelyingParty.find(key)
      end
      render layout: 'authentication'
    else
      redirect_to root_path unless personal_data.present?
    end
  end

end
