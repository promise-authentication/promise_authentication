require 'test_helper'

class Authentication::PersonalDataTest < ActiveSupport::TestCase
  test 'adding email' do
    data = Authentication::PersonalData.new
    data.add_email 'hello@example.com'

    json = data.to_json

    parsed = Authentication::PersonalData.new(JSON.parse(json))
    assert_equal parsed.emails, ['hello@example.com']
  end
end
