require 'test_helper'

class Authentication::IdTokenTest < ActiveSupport::TestCase
  test 'generating key pair' do
    assert Authentication::IdToken.generate_key_pair
  end

  test 'encode' do
    token = Authentication::IdToken.new(
      sub: 'hello',
    )

    id_token = token.to_s

    new_token = Authentication::IdToken.parse(id_token)

    assert_equal new_token.sub, 'hello'
  end
end
