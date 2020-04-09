require 'test_helper'

class Authentication::IdTokenTest < ActiveSupport::TestCase
  test 'encode' do
    token = Authentication::IdToken.new(
      sub: 'hello'
    )

    assert_equal token.to_s, 'hello'
  end
end
