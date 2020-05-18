require 'test_helper'

class Authentication::Services::EncryptVaultKeyTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::EncryptVaultKey
    @vault_key = 'bubble-babble'
    @user_id = 'uid'

    @private_key_off_site = 'alkwejwelkhwefhweflkwefkekwkwjek'
    @off_site_private_key = RbNaCl::PrivateKey.new(@private_key_off_site.b)
    @off_site_public_key = @off_site_private_key.public_key

    @key = Trust::KeyPair.new(
      public_key: Base64.strict_encode64(@off_site_public_key),
      private_key: Base64.strict_encode64(@off_site_private_key)
    )
  end

  test 'should save keys and be able to decrypt' do
    Trust::KeyPair.stub :create, @key do
      Trust::KeyPair.stub :find, @key do
        vault_key_cipher, key_pair_id = @described_class.call(@vault_key, @user_id)

        uniq_key_pair = Authentication::KeyPair.find(key_pair_id)
        uniq_public_key = Base64.strict_decode64(uniq_key_pair.public_key_base64)

        box = RbNaCl::SimpleBox.from_keypair(
          uniq_public_key,
          @off_site_private_key
        )

        decrypted_vault_key = box.decrypt(Base64.strict_decode64(vault_key_cipher))

        assert_equal decrypted_vault_key.encode('utf-8'), @vault_key

        # The keys should belong to user
        assert_equal 1, Authentication::KeyPair.where(user_id: @user_id).count
      end
    end
  end
end

