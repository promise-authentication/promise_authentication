require 'test_helper'

class Authentication::Services::Authenticate::ExistingTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::Authenticate::Existing
    @email = 'email@example.com'
    @password = 'secr3t'
  end

  test 'when nothing there' do
    assert_nil @described_class.call(@email, @password)
  end

  test 'knows not known' do
    assert_not @described_class.known?(@email)
  end

  test 'when something there' do
    Authentication::HashedEmail.stub :user_id_for_cleartext, 'uid' do
      mock = Minitest::Mock.new
      mock.expect :match!, true, [@password]
      mock.expect :vault_key_salt, Authentication::Vault.generate_salt
      Authentication::Password.stub :find, mock do
        uid, key = @described_class.call(@email, @password)
        assert_equal 'uid', uid
        assert key

        assert_mock mock
      end
    end
  end

  test 'when something there it knows' do
    Authentication::HashedEmail.stub :user_id_for_cleartext, 'uid' do
      assert @described_class.known?(@email)
    end
  end
end
