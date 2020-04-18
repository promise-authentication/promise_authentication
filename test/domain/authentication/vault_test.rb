require 'test_helper'

class Authentication::VaultTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Vault

    @salt = "e434f15f-919d-47e0-8cf9-98c38a7b41bd"
    @password = 'secret'
    @key = Authentication::Vault.key_from(@password, @salt)

    @wrong_key = Authentication::Vault.key_from('hello', 'world')
    @vault = Authentication::Vault.new(
      key: @key
    )
  end

  test 'key' do
    assert_equal Encoding::UTF_8, @key.encoding
    assert_equal 'xulog-gycyh-hanas-kezyp-zoniz-ha', @key
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
