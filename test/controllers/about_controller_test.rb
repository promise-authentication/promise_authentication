require 'test_helper'

class AboutControllerTest < ActionDispatch::IntegrationTest
  test 'privacy policy is served at /privacy' do
    get '/privacy'

    assert_response :success
    assert_includes response.body, 'Privacy Policy'
  end
end
