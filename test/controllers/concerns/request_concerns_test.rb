require 'test_helper'

# Behaviour every page gets from the concerns in ApplicationController.
class RequestConcernsTest < ActionDispatch::IntegrationTest
  test 'a locale param switches the language and is remembered' do
    get login_path(locale: 'da')
    assert_response :success
    assert_equal 'da', cookies[:locale]

    get login_path
    assert_select 'html[lang=da]'
  end

  test 'an unknown locale falls back to the default language' do
    get login_path(locale: 'xx')

    assert_response :success
    assert_select "html[lang=#{I18n.default_locale}]"
  end

  test 'a back param returns to the same page without it, sliding in from the left' do
    get login_path(back: true, email: 'hello@world.com')

    # /a is the first route to registrations#new, so url_for picks it.
    assert_redirected_to login_short_path(email: 'hello@world.com')
    assert_equal 'a-slide-in-from-left', flash[:slide_class]
  end

  test 'a signed-in user without a unique mark still gets pages' do
    auth = Authentication::Services::Authenticate.new(email: 'hello@world.com', password: 'secret').register!
    post authenticate_url, params: { email: 'hello@world.com', password: 'secret' }
    Authentication::SomethingUnique.where(id: auth.user_id).delete_all

    get '/password/edit'

    assert_response :success
    assert_select 'a[href="/uniq"]', count: 0
  end

  test 'a redirect_uri that does not parse is not a custom-scheme handoff' do
    controller = ApplicationController.new
    controller.params = ActionController::Parameters.new(redirect_uri: 'oase://not a uri')

    assert_equal false, controller.custom_scheme_handoff?
  end
end
