require 'test_helper'

class Admin::RelyingPartiesControllerTest < ActionDispatch::IntegrationTest
  test 'show' do
    Authentication::RelyingParty.stub :fetch, nil do
      get '/admin/relying_parties/example.com'
      assert_response :success
    end
  end
end
