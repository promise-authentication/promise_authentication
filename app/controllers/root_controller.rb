class RootController < ApplicationController
  before_action :authenticate
  before_action :verify_root

  private

  def verify_root
    root_user_ids = ENV.fetch('PROMISE_ROOT_USER_IDS') { '' }.split(',')
    redirect_to login_path unless root_user_ids.include?(current_user_id)
  end
end