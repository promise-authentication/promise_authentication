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

    content = Authentication::VaultContent.find(user_id)
    assert content

    # Now make sure the vault content can be decrypted
    key = Authentication::Vault.key_from(@password, salt)
    assert Authentication::Vault.new(key: key).decrypt(content.encrypted_personal_data)
  end
end

