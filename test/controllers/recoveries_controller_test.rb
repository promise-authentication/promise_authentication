require 'test_helper'

class RecoveriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    private_key_off_site = 'alkwejwelkhwefhweflkwefkekwkwjek'
    @off_site_private_key = RbNaCl::PrivateKey.new(private_key_off_site.b)
    off_site_public_key = @off_site_private_key.public_key

    @old_key =ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION']
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.strict_encode64(off_site_public_key.to_s).encode('utf-8')
  end

  teardown do
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = @old_key
  end

  test 'recovering password' do
    # First let's make the account
    email = 'hello@world.dk'
    auth = Authentication::Services::Authenticate.new(
      email: email,
      password: 'secret'
    ).call!

    user_id = auth.user_id

    # Now we make the account recoverable
    make = Authentication::Services::MakeRecoverable.new(user_id: user_id)
    info = make.info
    public_key = Base64.strict_decode64(info[:public_key_base64])
    vault_cipher = Base64.strict_decode64(info[:vault_key_cipher_base64])

    # Decrypt the key off-site
    box = RbNaCl::SimpleBox.from_keypair(
      public_key.b,
      @off_site_private_key
    )
    vault_key = box.decrypt(vault_cipher)

    # Make the vault key recoverable
    make.encrypt!(vault_key)

    # Get the view
    get key_recovery_path(id: user_id, key_id: make.secret_key)
    # Set new password
    put key_recovery_path(id: user_id, key_id: make.secret_key, new_password: 'hello')
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
