require 'application_system_test_case'

# Exercises the client-side behaviour of the single "smart" identifier field
# (shared/_identifier_field): type detection, the country selector, and routing
# the typed value to the right :email / :phone param on submit. None of this is
# reachable from the request tests, which post the params directly.
class IdentifierFieldTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  setup do
    @email = 'known@gmail.com' # a domain EmailInquire accepts as valid
    Authentication::Services::Authenticate.new(email: @email, password: 'secret').register!

    @phone = '+4520123456'
    Authentication::Services::Authenticate.new(phone: @phone, password: 'secret').register!
  end

  test 'the country selector and help text follow what is typed' do
    visit login_path

    # E-mail by default: no country selector, e-mail help showing.
    assert_selector '#phone-country', visible: :hidden
    assert_selector '.js-when-email', visible: :visible
    assert_no_selector '.js-when-phone', visible: :visible

    # A national number reveals the selector and swaps to the phone help.
    fill_in 'email', with: '20 12 34 56'
    assert_selector '#phone-country', visible: :visible
    assert_selector '.js-when-phone', visible: :visible
    assert_no_selector '.js-when-email', visible: :visible

    # A full +number is self-contained: phone mode, but no duplicate dial code.
    fill_in 'email', with: '+45 20 12 34 56'
    assert_selector '.js-when-phone', visible: :visible
    assert_selector '#phone-country', visible: :hidden

    # Back to an e-mail hides the selector again.
    fill_in 'email', with: 'someone@example.com'
    assert_selector '#phone-country', visible: :hidden
    assert_selector '.js-when-email', visible: :visible
  end

  test 'a full +number prefilled from the URL splits into the selector and field' do
    visit login_path(phone: '+45 20442127')

    # The dial code shows once, in the selector; the field holds the national part.
    assert_selector '#phone-country', visible: :visible
    assert_equal '+45', find('#phone-country').value
    assert_equal '20442127', find('#email').value
  end

  test 'a typed e-mail is submitted as the e-mail identifier' do
    visit login_path
    fill_in 'email', with: @email
    find("button[type='submit']").click

    # Known identifier → straight to the password screen.
    assert_current_path verify_password_path, ignore_query: true
  end

  test 'a typed national number is composed and submitted as the phone identifier' do
    visit login_path
    fill_in 'email', with: '20123456' # default region is +45
    assert_selector '#phone-country', visible: :visible
    find("button[type='submit']").click

    # Reaching the password screen proves the value was routed to :phone and the
    # phone account was found — an e-mail of "20123456" would never match.
    assert_current_path verify_password_path, ignore_query: true
  end
end
