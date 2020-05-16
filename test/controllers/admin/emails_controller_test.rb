require 'test_helper'

class Admin::EmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_params = {
      secret_key: Authentication::RelyingParty.new(id: 'example.com').secret_key_base64,
      email: 'hello@example.com'
    }
  end

  test 'authentication' do
    post '/admin/relying_parties/example.com/emails'
    assert_response :forbidden

    post '/admin/relying_parties/example.com/emails', params: {
      secret_key: 'hello'
    }
    assert_response :forbidden

    post '/admin/relying_parties/example.com/emails', params: @base_params
    assert_response :created
  end

  test 'creation and deletion' do
    post '/admin/relying_parties/example.com/emails', params: @base_params
    # And handles double
    post '/admin/relying_parties/example.com/emails', params: @base_params

    hashed_email = Authentication::HashedEmail.from_cleartext('hello@example.com')

    assert Authentication::RelyingPartyEmail.find_by_hashed_email(hashed_email)

    delete '/admin/relying_parties/example.com/emails/hello@example.com', params: @base_params
    assert_response :ok

    assert_nil Authentication::RelyingPartyEmail.find_by_hashed_email(hashed_email)
  end


end
