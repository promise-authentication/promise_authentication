require 'test_helper'

class Authentication::VaultTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Vault

    @salt = Base64.strict_decode64("P4lFPxhDVTIq64hUfdximV0/F2Pve/cJ6pwLHBwnS84=")
    @password = 'secret'
    @key = Authentication::Vault.key_from(@password, @salt)

    @wrong_key = Authentication::Vault.key_from('hello', @salt)
    @vault = Authentication::Vault.new(
      key: @key
    )
  end

  test 'key' do
    assert_equal Encoding::BINARY, @key.encoding
    assert_equal 'xlcblv/oBTVWNsbZujhxs1ptidTDrWPLCdIiQLVe8Hc=', Base64.strict_encode64(@key)
  end

  test 'using wrong then right password' do
    content = { hello: 'world' }

    enctrypted_content = @vault.encrypt(content)
    assert_not_equal enctrypted_content, content

    wrong = @described_class.new key: @wrong_key
    assert_raises RbNaCl::CryptoError do
      wrong.decrypt(enctrypted_content)
    end

    right = @described_class.new key: @key
    assert_equal right.decrypt(enctrypted_content), { 'hello' => 'world' }
  end
end
