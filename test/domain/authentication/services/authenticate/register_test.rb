require 'test_helper'

class Authentication::Services::Authenticate::RegisterTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::Authenticate::Register
    @email = 'anders@lemke.dk'
    @password = 'secr3t'

    @mocks = []
  end

  test 'when nothing there' do
    user_id, salt = @described_class.(@email, @password)

    assert_raises Authentication::Email::AlreadyClaimed do
      @described_class.(@email, @password)
    end

    assert Authentication::Password.find(user_id)
    assert Authentication::HashedEmail.find_by_user_id(user_id)

    # Now make sure the vault content can be decrypted
    key = Authentication::Vault.key_from(@password, salt)
    personal_data = Authentication::Vault.personal_data(user_id, key)
    assert personal_data

    # And that is has email
    assert_equal @email, personal_data.emails.first
  end
end

