class HumansController < ApplicationController

  def show
    redirect_to root_path unless personal_data.present?
  end

end
