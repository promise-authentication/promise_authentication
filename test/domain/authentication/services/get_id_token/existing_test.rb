require 'test_helper'

class Authentication::Services::GetIdToken::ExistingTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::GetIdToken::Existing
    @user_id = 'uid'
    @relying_party_id = 'example.com'
    @vault_key = 'foo'
  end

  test 'when nothing there' do
    personal_data = Minitest::Mock.new
    personal_data.expect :id_for, nil, [@relying_party_id]

    Authentication::Vault.stub :personal_data, personal_data do
      id = @described_class.(@user_id, @relying_party_id, @vault_key)
      assert_nil id

      assert_mock personal_data
    end
  end

  test 'when something there' do
    personal_data = Minitest::Mock.new
    personal_data.expect :id_for, 'rpid', [@relying_party_id]

    Authentication::Vault.stub :personal_data, personal_data do
      id = @described_class.(@user_id, @relying_party_id, @vault_key)
      assert_equal id, 'rpid'

      assert_mock personal_data
    end
  end
end

