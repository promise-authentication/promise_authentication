require 'test_helper'

class WellKnownsControllerTest < ActionDispatch::IntegrationTest
  test 'authentication' do
    get '/.well-known/jwks.json'
  end
end

