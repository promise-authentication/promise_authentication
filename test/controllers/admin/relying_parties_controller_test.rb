require 'test_helper'

class Admin::RelyingPartiesControllerTest < ActionDispatch::IntegrationTest

  test 'show' do
    get '/admin/relying_parties/example.com'
    assert_response :success
  end

end
