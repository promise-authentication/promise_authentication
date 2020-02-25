require 'test_helper'

class SetupRpFlowTest < ActionDispatch::IntegrationTest
  test "requesting setup to start" do
    post "/relying_parties/example.com/setup"
  end
end
