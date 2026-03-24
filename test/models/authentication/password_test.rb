require 'test_helper'

class Authentication::PasswordTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Password
  end

  test 'that a password can be hashed' do
    assert @described_class.digest_from('secret')
  end

  test 'a password can be verified' do
    user_id = 'uid'
    cleartext = 'secret'
    digest = @described_class.digest_from(cleartext)

    @described_class.create(id: user_id, digest: digest)

    assert @described_class.find(user_id).match!(cleartext)
    assert_not_equal digest, cleartext
  end
end
