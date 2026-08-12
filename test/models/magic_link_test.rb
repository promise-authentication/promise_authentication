require 'test_helper'

class MagicLinkTest < ActiveSupport::TestCase
  setup do
    @hashed_email = Authentication::HashedEmail.from_cleartext('someone@example.com')
    @payload = {
      'email' => 'someone@example.com',
      'code' => 'abcd',
      'redirect_uri' => 'https://rp.example.com/callback?state=secret'
    }
  end

  test 'redeems the payload it was issued with' do
    token = MagicLink.issue!(hashed_email: @hashed_email, payload: @payload)

    assert_equal @payload, MagicLink.redeem(token)
  end

  test 'stores the payload encrypted' do
    MagicLink.issue!(hashed_email: @hashed_email, payload: @payload)

    ciphertext = MagicLink.last.ciphertext
    assert_no_match(/someone@example.com/, ciphertext)
    assert_no_match(/rp\.example\.com/, ciphertext)
  end

  test 'does not redeem with a wrong secret' do
    token = MagicLink.issue!(hashed_email: @hashed_email, payload: @payload)
    id, _secret = token.split('.', 2)

    assert_nil MagicLink.redeem("#{id}.#{SecureRandom.urlsafe_base64(32)}")
  end

  test 'does not redeem an unknown id' do
    token = MagicLink.issue!(hashed_email: @hashed_email, payload: @payload)
    _id, secret = token.split('.', 2)

    assert_nil MagicLink.redeem("#{SecureRandom.hex(16)}.#{secret}")
  end

  test 'does not redeem a malformed token' do
    assert_nil MagicLink.redeem(nil)
    assert_nil MagicLink.redeem('')
    assert_nil MagicLink.redeem('no-separator')
  end

  test 'does not redeem after the TTL has passed' do
    token = MagicLink.issue!(hashed_email: @hashed_email, payload: @payload)
    MagicLink.last.update!(created_at: (MagicLink::TTL + 1.minute).ago)

    assert_nil MagicLink.redeem(token)
  end

  test 'reset_for! destroys the links for a hashed email' do
    token = MagicLink.issue!(hashed_email: @hashed_email, payload: @payload)
    other = MagicLink.issue!(hashed_email: 'other-hash', payload: @payload)

    MagicLink.reset_for!(@hashed_email)

    assert_nil MagicLink.redeem(token)
    assert_not_nil MagicLink.redeem(other)
  end
end
