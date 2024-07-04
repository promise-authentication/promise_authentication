require 'test_helper'

class Authentication::Services::AuthenticateTest < ActiveSupport::TestCase
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

  test 'downcasing and stripping email' do
    @request.email = ' Hello@example.com'
    assert_equal @request.email, 'hello@example.com'
  end

  test 'will lax-confirm email' do
    Authentication::Services::Authenticate::Register.stub :call, 'world' do
      @request.register!(email_confirmation: ' Hello@world.dk')
      assert_equal @request.user_id, 'world'
    end
  end

  test 'it will use existing' do
    Authentication::Services::Authenticate::Existing.stub :call, 'hello' do
      Authentication::Services::Authenticate::Register.stub :call, 'world' do
        @request.call!
        assert_equal @request.user_id, 'hello'
      end
    end
  end

  test 'it will create a new if no existing' do
    Authentication::Services::Authenticate::Existing.stub :call, nil do
      @request.call!
      assert_nil @request.user_id
    end
  end
end
