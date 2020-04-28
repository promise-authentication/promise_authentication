class LandingController < ApplicationController
  before_action :set_view_paths
  skip_around_action :switch_locale

  private

  def set_view_paths
    prepend_view_path 'app/views/landing'
  end
end
