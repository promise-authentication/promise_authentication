require 'test_helper'

class Authentication::PersonalDataTest < ActiveSupport::TestCase
  test 'adding email' do
    data = Authentication::PersonalData.new
    json = data.to_json
    parsed = Authentication::PersonalData.new(JSON.parse(json))
    assert parsed
  end

  test 'reading and getting id' do
    data = Authentication::PersonalData.new
    party = 'example.com'
    id = 'id'

    assert_nil data.id_for(party)

    data.add_id(id, party)

    assert_equal id, data.id_for(party)

    json = data.to_json
    parsed = Authentication::PersonalData.new(JSON.parse(json))
    assert_equal id, parsed.id_for(party)
  end
end
