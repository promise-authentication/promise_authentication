require 'test_helper'

class HumansControllerTest < ActionDispatch::IntegrationTest
  test 'the login screen' do
    get login_url
    assert_response :success

    assert_select 'input#email'
    assert_select 'input#password'
  end

  test 'authenticating with nothing' do
    post authenticate_url
    assert_response :redirect
  end
end
