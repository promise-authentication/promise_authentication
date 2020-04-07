require 'test_helper'

class Authentication::Services::AuthenticationTest < ActiveSupport::TestCase
  setup do
    @request = Authentication::Services::Authenticate.new(
      email: 'hello@world.dk',
      password: 'secret'
    )
  end

  test 'not valid' do
    @request.email = nil
    assert_not @request.valid?
  end

  test 'valid' do
    assert @request.valid?
  end

  test 'it will try finding existing' do
  end

end
