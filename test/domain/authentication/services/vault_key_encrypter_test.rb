require 'test_helper'

class Authentication::Services::VaultKeyEncrypterTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::VaultKeyEncrypter
    @vault_key = 'bubble-babble'

    @private_key_off_site = 'alkwejwelkhwefhweflkwefkekwkwjek'
    @private_key_on_site  = 'lkekejejejwnwmkdejkekhejwlekwekj'

    @off_site_private_key = RbNaCl::PrivateKey.new(@private_key_off_site.b)
    off_site_public_key = @off_site_private_key.public_key
    ENV['PROMISE_PUBLIC_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.strict_encode64(off_site_public_key.to_s).encode('utf-8')

    on_site_private_key = RbNaCl::PrivateKey.new(@private_key_on_site.b)
    @on_site_public_key = on_site_private_key.public_key

    ENV['PROMISE_PRIVATE_KEY_FOR_VAULT_KEY_ENCRYPTION'] = Base64.strict_encode64(on_site_private_key.to_s).encode('utf-8')
  end

  test 'should save keys and be able to decrypt' do
    vault_key_cipher, uniq_public_key_id = @described_class.call(@vault_key)

    uniq_key_pair = Authentication::KeyPair.find(uniq_public_key_id)

    box_for_private_key = RbNaCl::SimpleBox.from_keypair(
      @on_site_public_key,
      @off_site_private_key
    )

    uniq_private_key = box_for_private_key.decrypt(
      Base64.strict_decode64(uniq_key_pair.private_key_cipher_base64)
    )

    box_for_vault_key = RbNaCl::SimpleBox.from_keypair(
      @on_site_public_key,
      uniq_private_key
    )

    decrypted_vault_key = box_for_vault_key.decrypt(Base64.strict_decode64(vault_key_cipher))

    assert_equal decrypted_vault_key.encode('utf-8'), @vault_key
  end
end

