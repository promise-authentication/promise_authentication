require 'test_helper'

class WellKnownsControllerTest < ActionDispatch::IntegrationTest
  test 'authentication' do
    Trust::Certificate.rotate!

    get '/.well-known/jwks.json'

    json = JSON.parse(response.body)
    assert_equal 1, json['keys'].size
    assert_equal 'ES512', json['keys'][0]["alg"]
  end

  # Answered by the router itself, not by an unmatched-route RoutingError
  # (which would also render a 404, but logs an exception for every probe).
  test 'passkey endpoints are not offered' do
    get '/.well-known/passkey-endpoints'

    assert_response :not_found
    assert_equal 'Not Found', response.body
  end
end
