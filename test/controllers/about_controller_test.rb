require 'test_helper'

class AboutControllerTest < ActionDispatch::IntegrationTest
  test 'privacy policy is served at /privacy' do
    get '/privacy'

    assert_response :success
    assert_includes response.body, 'Privacy Policy'
  end

  test 'the comparison table lists every provider' do
    get '/about/comparison'

    assert_response :success
    %w[Promise OpenID Google Auth0].each { |provider| assert_includes response.body, provider }
  end

  test 'the data page shows what is stored for a test user, also on repeat visits' do
    stub_request(:get, %r{\Ahttps://(oase\.app|example\.com)/\.well-known/promise\.json\z}).to_return(status: 404)

    get '/about/data'
    assert_response :success

    # The test user now exists, so the page signs it in instead of registering.
    get '/about/data'
    assert_response :success
    assert_includes response.body, 'test@example.com'
  end
end
