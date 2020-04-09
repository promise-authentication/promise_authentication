require 'test_helper'

class Authentication::IdentityTest < ActiveSupport::TestCase
  test 'can claim many, but not reclaim' do
    identity = Authentication::Identity.new('id')

    identity.claim(relying_party_id: 'hello')
    identity.claim(relying_party_id: 'world')

    assert_raises Authentication::Identity::AlreadyClaimed do
      identity.claim(relying_party_id: 'hello')
    end
  end

end
