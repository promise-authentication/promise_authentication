require 'test_helper'

class Authentication::Services::GetIdToken::RegisterTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::GetIdToken::Register
    @email = 'anders@lemke.dk'
    @password = 'secr3t'
    authentication = Authentication::Services::Authenticate.new(
      email: @email, 
      password: @password
    ).register!
    @user_id = authentication.user_id
    @vault_key = authentication.vault_key

    @relying_party_id = 'example.com'
  end

  test 'when nothing there' do
    new_id = @described_class.(@user_id, @relying_party_id, @vault_key)

    personal_data = Authentication::Vault.personal_data(@user_id, @vault_key)
    assert personal_data

    # And that is has id
    assert_equal new_id, personal_data.id_for(@relying_party_id)
  end
end

