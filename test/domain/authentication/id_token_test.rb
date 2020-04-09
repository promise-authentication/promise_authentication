require 'test_helper'

class Authentication::IdTokenTest < ActiveSupport::TestCase
  test 'encode' do
    token = Authentication::IdToken.new(
      sub: 'hello'
    )

  end
end
