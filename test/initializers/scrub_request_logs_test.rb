require 'test_helper'

class ScrubRequestLogsTest < ActiveSupport::TestCase
  def log_line_for(remote_addr)
    logger = Rails::Rack::Logger.new(->(_env) { [200, {}, []] })
    request = ActionDispatch::Request.new(
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/login',
      'REMOTE_ADDR' => remote_addr,
      'rack.input' => StringIO.new
    )
    logger.send(:started_request_message, request)
  end

  test 'request log lines mask the client IP like Ahoy does' do
    line = log_line_for('203.0.113.77')

    assert_includes line, '203.0.113.0'
    assert_not_includes line, '203.0.113.77'
  end

  test 'ipv6 addresses are masked too' do
    line = log_line_for('2001:db8:abcd:1234:5678:9abc:def0:1234')

    assert_includes line, '2001:db8:abcd::'
    assert_not_includes line, '5678'
  end
end
