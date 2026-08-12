require 'test_helper'

class Root::FunnelControllerTest < ActionDispatch::IntegrationTest
  test 'requires a signed-in root user' do
    get '/root/funnel'
    assert_redirected_to %r{/login}
  end
end
