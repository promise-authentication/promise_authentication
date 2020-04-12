class HumansController < ApplicationController

  def show
    if personal_data.present?
      render layout: 'authentication'
    else
      redirect_to root_path unless personal_data.present?
    end
  end

end
