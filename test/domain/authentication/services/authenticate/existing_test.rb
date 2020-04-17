require 'test_helper'

class Authentication::Services::Authenticate::ExistingTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::Authenticate::Existing
    @email = 'email@example.com'
    @password = 'secr3t'
  end

  test 'when nothing there' do
    assert_nil @described_class.(@email, @password)
  end

  test 'when something there' do
    Authentication::HashedEmail.stub :user_id_for_cleartext, 'uid' do
      mock = Minitest::Mock.new
      mock.expect :match!, true, [@password]
      mock.expect :vault_key_salt, 'salt'
      Authentication::Password.stub :find, mock do

        uid, key = @described_class.(@email, @password)
        assert_equal 'uid', uid
        assert key

        assert_mock mock
      end
    end
  end
end

