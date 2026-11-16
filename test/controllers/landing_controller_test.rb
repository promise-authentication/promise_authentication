require 'test_helper'

class LandingControllerTest < ActionDispatch::IntegrationTest
  test 'the landing page is served at the root' do
    get '/'

    assert_response :success
    assert_select 'h1'
  end
end
