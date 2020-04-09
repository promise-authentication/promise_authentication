require 'test_helper'

class Authentication::Services::GetIdTokenTest < ActiveSupport::TestCase
  setup do
    @request = Authentication::Services::GetIdToken.new(
      user_id: 'id',
      relying_party_id: 'pid',
      vault_key: 'key'
    )
  end

  test 'not valid' do
    @request.user_id = nil
    assert_not @request.valid?
  end

  test 'valid' do
    assert @request.valid?
  end

  test 'it will use existing' do
    Authentication::Services::GetIdToken::Existing.stub :call, 'hello' do
      Authentication::Services::GetIdToken::Register.stub :call, 'world' do
        token = @request.id_token
        assert_equal token.sub, 'hello'
        assert_equal token.aud, 'pid'
        assert token.to_s
      end
    end
  end

  test 'it will create a new if no existing' do

    Authentication::Services::GetIdToken::Existing.stub :call, nil do
      Authentication::Services::GetIdToken::Register.stub :call, 'world' do
        token = @request.id_token
        assert_equal token.sub, 'world'
        assert_equal token.aud, 'pid'
        assert token.to_s
      end
    end
  end
end
