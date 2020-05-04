require 'test_helper'

class Authentication::VaultKeysForRecoveryTest < ActiveSupport::TestCase
  test 'when asking for info on existing account' do
    email = 'hello@world.com'

    authentication = Authentication::Services::Authenticate.new(
      email: email,
      password: 'secret'
    ).call!

    user_id = authentication.user_id

    info = Authentication::VaultKeysForRecovery.find(user_id).info
    assert info[:public_key_base64]
  end
end
