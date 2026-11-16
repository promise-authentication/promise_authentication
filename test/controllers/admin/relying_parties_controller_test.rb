require 'test_helper'

class Admin::RelyingPartiesControllerTest < ActionDispatch::IntegrationTest
  test 'show' do
    Authentication::RelyingParty.stub :fetch, nil do
      get '/admin/relying_parties/example.com'
      assert_response :success
    end
  end

  test 'index shows the getting-started form' do
    get '/admin/relying_parties'
    assert_response :success
  end

  test 'index sends a submitted domain on to its page, example.com when blank' do
    get '/admin/relying_parties', params: { id: 'my.site' }
    assert_redirected_to admin_relying_party_path(id: 'my.site')

    get '/admin/relying_parties', params: { id: '' }
    assert_redirected_to admin_relying_party_path(id: 'example.com')
  end
end
