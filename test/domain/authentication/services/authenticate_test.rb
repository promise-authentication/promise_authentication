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

  test 'downcasing email' do
    @request.email = 'Hello@example.com'
    assert_equal @request.email, 'hello@example.com'
  end

  test 'it will use existing' do
    Authentication::Services::Authenticate::Existing.stub :call, 'hello' do
      Authentication::Services::Authenticate::Register.stub :call, 'world' do
        user_id, salt = @request.user_id_and_vault_key
        assert_equal user_id, 'hello'
      end
    end
  end

  test 'it will create a new if no existing' do
    Authentication::Services::Authenticate::Existing.stub :call, nil do
      Authentication::Services::Authenticate::Register.stub :call, 'world' do
        user_id, key = @request.user_id_and_vault_key
        assert_equal user_id, 'world'
      end
    end
  end
end
