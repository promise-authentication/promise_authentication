require 'test_helper'

class Authentication::RelyingPartyTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::RelyingParty
    @relying_party = @described_class.new
  end

  test 'it will call the well knowns' do
    response = Minitest::Mock.new
    response.expect :body, {
      legacy_account_authentication_url: 'https://url',
      legacy_account_forgot_password_url: 'https://forgot'
    }.to_json
    @described_class.stub :fetch, response do
      @relying_party = Authentication::RelyingParty.find('foo')
    end
    assert @relying_party
    assert @relying_party.supports_legacy_accounts?
  end

  test 'it will require legacy url to have https' do
    assert @relying_party.valid?
    @relying_party.legacy_account_authentication_url = 'http://hello.world'
    assert_not @relying_party.valid?
    @relying_party.legacy_account_authentication_url = 'https://hello.world'
    assert @relying_party.valid?
  end

  test 'authenticating legacy account' do
    @relying_party.legacy_account_authentication_url = 'https://hello.world'
    @relying_party.legacy_account_forgot_password_url = 'http://hello.world'

    response = Minitest::Mock.new
    response.expect :code, 200
    response.expect :body, {
      user_id: 'uid'
    }.to_json
    @described_class.stub :fetch, response do
      assert_equal @relying_party.legacy_account_user_id_for(
        'email',
        'password'
      ), 'uid'
    end
  end
end
