class AboutController < ApplicationController
  def welcome
  end

  def open
    render layout: 'application'
  end
end
