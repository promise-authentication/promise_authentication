require 'test_helper'

class Root::RelyingPartiesControllerTest < ActionDispatch::IntegrationTest
  teardown { ENV.delete('PROMISE_ROOT_USER_IDS') }

  test 'requires a root user' do
    Authentication::Services::Authenticate.new(email: 'someone@example.com', password: 'secret').register!
    post authenticate_url, params: { email: 'someone@example.com', password: 'secret' }

    get '/root/relying_parties'
    assert_redirected_to login_path
  end

  test 'lists tokens generated per relying party' do
    Authentication::Services::Authenticate.new(email: 'root@example.com', password: 'secret').register!
    ENV['PROMISE_ROOT_USER_IDS'] = Authentication::HashedEmail.user_id_for_cleartext('root@example.com')
    post authenticate_url, params: { email: 'root@example.com', password: 'secret' }
    Statistics::SignInEvent.create!(relying_party_id: 'example.com', user_id: 'someone')

    get '/root/relying_parties'

    assert_response :success
    assert_includes response.body, 'example.com'
  end
end
