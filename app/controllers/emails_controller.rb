class EmailsController < ApplicationController
  before_action :authenticate

  layout 'authentication'

  def update
    begin
      Authentication::Services::ChangeEmail.new(
        user_id: current_user_id,
        old_email: email,
        new_email: params[:email]
      ).call!
    rescue Authentication::Email::AlreadyClaimedByYou
      # OK, you probably did it in another browser
    end

    cookies.encrypted.permanent[:email] = params[:email]

    redirect_to dashboard_path
  rescue Authentication::Email::AlreadyClaimed
    flash[:warning] = t('.email_already_claimed')
    redirect_to email_path
  rescue Authentication::Email::NotYoursToRelease
    do_logout!
    redirect_to login_path
  end

  def show
  end

end
