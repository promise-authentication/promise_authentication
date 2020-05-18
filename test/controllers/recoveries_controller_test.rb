require 'test_helper'

class RecoveriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    private_key_off_site = 'alkwejwelkhwefhweflkwefkekwkwjek'
    @off_site_private_key = RbNaCl::PrivateKey.new(private_key_off_site.b)
    off_site_public_key = @off_site_private_key.public_key
  end

  test 'recovering password' do
    # First let's make the account
    email = 'hello@world.dk'
    auth = Authentication::Services::Authenticate.new(
      email: email,
      password: 'secret'
    ).call!

    user_id = auth.user_id

    # Request the recovery
    Authentication::Services::SendRecoveryMail.new(email: email).call
    token = Authentication::RecoveryToken.find_by_user_id(user_id).token

    # Get the view
    get token_recoveries_path(token_id: token)
    # Set new password
    post token_recoveries_path(token_id: token, new_password: 'hello')
    assert_redirected_to login_path

    # Sign in with new password:
    post authenticate_url, params: { email: email, password: 'hello', remember_me: 1 }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal email, jar.encrypted[:email]

    vault_key = jar.encrypted[:vault_key]
    assert Authentication::Vault.personal_data(user_id, vault_key)
  end
end
