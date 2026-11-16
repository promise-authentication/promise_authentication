require 'test_helper'

class RecoveriesControllerTest < ActionDispatch::IntegrationTest
  test 'recovering password' do
    # First let's make the account
    email = 'hello@world.dk'
    auth = Authentication::Services::Authenticate.new(
      email: email,
      password: 'secret'
    ).register!

    user_id = auth.user_id

    # Request the recovery
    Authentication::Services::SendRecoveryMail.new(email: email).call
    token = Authentication::RecoveryToken.find_by_user_id(user_id).token

    # Get the view
    get token_recoveries_path(token_id: token)
    # Set new password
    post token_recoveries_path(token_id: token, new_password: 'hello')
    assert_redirected_to login_path

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:user_id]
    assert_nil jar.encrypted[:email]

    # It will not accept more
    get token_recoveries_path(token_id: token)
    assert_redirected_to root_path

    # Sign in with new password:
    post authenticate_url, params: { email: email, password: 'hello', remember_me: 1 }

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal user_id, jar.encrypted[:user_id]
    assert_equal email, jar.encrypted[:email]

    vault_key = Base64.strict_decode64(jar.encrypted[:vault_key_base64])
    assert Authentication::Vault.personal_data(user_id, vault_key)
  end

  def recovery_token_for(email)
    Authentication::Services::Authenticate.new(email: email, password: 'secret').register!
    Authentication::Services::SendRecoveryMail.new(email: email).call
    Authentication::RecoveryToken.last.token
  end

  test 'an unknown token goes to the front page' do
    get token_recoveries_path(token_id: 'nope')
    assert_redirected_to root_path
  end

  test 'a blank new password shows the form again' do
    token = recovery_token_for('hello@world.dk')

    post token_recoveries_path(token_id: token, new_password: '')

    assert_response :success
    assert Authentication::RecoveryToken.find_by_token(token), 'the token is still usable'
  end

  test 'a recovery that cannot be decrypted sends the user to login' do
    token = recovery_token_for('hello@world.dk')
    failing = Object.new
    def failing.call! = raise(RbNaCl::CryptoError)

    Authentication::Services::RecoverySetPassword.stub :new, ->(*) { failing } do
      post token_recoveries_path(token_id: token, new_password: 'hello')
    end

    assert_redirected_to login_path
  end
end
