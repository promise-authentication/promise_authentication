require 'test_helper'

class Authentication::Services::MakeRecoverableTest < ActionDispatch::IntegrationTest
  setup do
    @described_class = Authentication::Services::MakeRecoverable

    private_key_off_site = 'alkwejwelkhwefhweflkwefkekwkwjek'
    @off_site_private_key = RbNaCl::PrivateKey.new(private_key_off_site.b)
    off_site_public_key = @off_site_private_key.public_key

    @old_key =ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION']
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.strict_encode64(off_site_public_key.to_s).encode('utf-8')
  end

  teardown do
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = @old_key
  end

  test 'will make vault key accessible and decryptable' do
    email = 'hello@world.dk'
    auth = Authentication::Services::Authenticate.new(
      email: email,
      password: 'secret'
    ).call!

    user_id = auth.user_id

    make = @described_class.new(user_id: user_id)
    info = make.info
    public_key = Base64.strict_decode64(info[:public_key_base64])
    vault_cipher = Base64.strict_decode64(info[:vault_key_cipher_base64])

    box = RbNaCl::SimpleBox.from_keypair(
      public_key.b,
      @off_site_private_key
    )
    vault_key = box.decrypt(vault_cipher)

    assert_equal vault_key, auth.vault_key

    make.encrypt!(vault_key)

    recovery = Authentication::VaultKeysForRecovery.find(user_id)
    assert_equal vault_key, recovery.recovered_vault_key(make.secret_key)

    assert_emails 1 do
      make.send!(email, 'en')
      recover_url = key_recovery_path(id: user_id, key_id: make.secret_key)
      sent = ActionMailer::Base.deliveries.first
      assert_equal [email], sent.to
      assert_includes sent.text_part.body.to_s, recover_url
      assert_includes sent.html_part.body.to_s, recover_url
    end
  end
end
