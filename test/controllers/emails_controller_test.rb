require 'test_helper'

class EmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @email = 'hello@world.com'
    post '/authenticate', params: { email: @email, password: 'secret' }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    @user_id = jar.encrypted[:user_id]
  end

  test 'form for new email' do
    get '/email'
    assert_response :success
  end

  test 'setting new email' do
    new_email = 'hello@example.dk'
    put '/email', params: { email: new_email }

    assert_redirected_to dashboard_path

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal new_email, jar.encrypted[:email]

    delete '/logout'
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:email]

    post '/authenticate', params: { email: new_email, password: 'secret' }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal new_email, jar.encrypted[:email]
    assert_equal @user_id, jar.encrypted[:user_id]
  end

  test 'setting new email in other browser' do
    new_email = 'hello@example.dk'

    # Simulate setting in other browser
    Authentication::Services::ChangeEmail.new(
      user_id: @user_id,
      old_email: @email,
      new_email: new_email
    ).call!

    put '/email', params: { email: new_email }

    assert_redirected_to dashboard_path

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal new_email, jar.encrypted[:email]

    delete '/logout'
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:email]

    post '/authenticate', params: { email: new_email, password: 'secret' }
    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_equal new_email, jar.encrypted[:email]
    assert_equal @user_id, jar.encrypted[:user_id]
  end

  test 'setting new email in other browser and then changing it to something new again' do
    new_email = 'hello@example.dk'

    # Simulate setting in other browser
    Authentication::Services::ChangeEmail.new(
      user_id: @user_id,
      old_email: @email,
      new_email: new_email
    ).call!

    newer_email = 'new@example.com'

    put '/email', params: { email: newer_email }

    assert_redirected_to login_path

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    assert_nil jar.encrypted[:email]
    assert_nil jar.encrypted[:user_id]
    assert_nil jar.encrypted[:vault_key]
  end

  test 'trying to claim someone elses email' do
    other_email = 'foo@bar.com'
    post '/authenticate', params: { email: other_email, password: 'secret' }
    # Now I'm singed in as someone else

    # Now claim that first email
    put '/email', params: { email: @email }

    assert_redirected_to email_path
  end
end
