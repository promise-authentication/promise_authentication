require 'test_helper'

class Authentication::IdTokenTest < ActiveSupport::TestCase

  test 'encode' do
    Trust::Certificate.rollover!

    token = Authentication::IdToken.new(
      sub: 'hello',
      nonce: 'nonce'
    )

    id_token = token.to_s

    new_token = Authentication::IdToken.parse(id_token)

    assert_equal new_token.sub, 'hello'
    assert_equal new_token.nonce, 'nonce'
  end
end
