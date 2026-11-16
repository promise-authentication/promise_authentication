require 'test_helper'

class HumansControllerTest < ActionDispatch::IntegrationTest
  def sign_in
    Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post authenticate_url, params: { email: 'hello@world.com', password: 'secret', remember_me: 1 }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    [jar.encrypted[:user_id], Base64.strict_decode64(jar.encrypted[:vault_key_base64])]
  end

  test 'the dashboard requires a signed-in user' do
    get '/me'
    assert_redirected_to login_path(redirect_to: 'http://www.example.com/me')
  end

  test 'the dashboard lists the relying parties the user has an id with' do
    user_id, vault_key = sign_in
    id_token = Authentication::Services::GetIdToken.new(
      user_id: user_id, relying_party_id: 'example.com', vault_key: vault_key
    ).id_token

    get '/me'

    assert_response :success
    assert_includes response.body, 'https://example.com'
    assert_includes response.body, id_token.sub
  end

  test 'uniq is served' do
    sign_in
    get '/uniq'
    assert_response :success
  end
end
