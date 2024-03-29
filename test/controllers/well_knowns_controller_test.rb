require 'test_helper'

class WellKnownsControllerTest < ActionDispatch::IntegrationTest
  test 'authentication' do
    Trust::Certificate.rotate!

    get '/.well-known/jwks.json'

    json = JSON.parse(response.body)
    assert_equal 1, json['keys'].size
    assert_equal 'ES512', json['keys'][0]["alg"]
  end
end

