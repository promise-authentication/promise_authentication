require 'test_helper'

class Authentication::Services::VaultKeyEncrypterTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::VaultKeyEncrypter
    @vault_key = 'bubble-babble'

    @private_key_off_site = 'alkwejwelkhwefhweflkwefkekwkwjek'
    @off_site_private_key = RbNaCl::PrivateKey.new(@private_key_off_site.b)
    @off_site_public_key = @off_site_private_key.public_key

    @old_key =ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION']
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.strict_encode64(@off_site_public_key.to_s).encode('utf-8')
  end

  teardown do
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = @old_key
  end

  test 'should save keys and be able to decrypt' do
    vault_key_cipher, key_pair_id = @described_class.call(@vault_key)

    uniq_key_pair = Authentication::KeyPair.find(key_pair_id)
    uniq_public_key = Base64.strict_decode64(uniq_key_pair.public_key_base64)

    box = RbNaCl::SimpleBox.from_keypair(
      uniq_public_key,
      @off_site_private_key
    )

    decrypted_vault_key = box.decrypt(Base64.strict_decode64(vault_key_cipher))

    assert_equal decrypted_vault_key.encode('utf-8'), @vault_key
  end
end

