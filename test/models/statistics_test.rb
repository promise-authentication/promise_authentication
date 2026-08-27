require 'test_helper'

class StatisticsTest < ActiveSupport::TestCase
  test 'sweep_old! deletes visit statistics older than the retention period' do
    old_visit = Ahoy::Visit.create!(started_at: (Statistics::RETENTION + 1.day).ago)
    Ahoy::Event.create!(visit: old_visit, name: 'old', time: (Statistics::RETENTION + 1.day).ago)

    fresh_visit = Ahoy::Visit.create!(started_at: 1.day.ago)
    Ahoy::Event.create!(visit: fresh_visit, name: 'fresh', time: 1.day.ago)

    Statistics.sweep_old!

    assert_equal [fresh_visit.id], Ahoy::Visit.pluck(:id)
    assert_equal ['fresh'], Ahoy::Event.pluck(:name)
  end

  test 'sweep_old! keeps sign-in events — they feed the all-time per-service counts' do
    old_sign_in = Statistics::SignInEvent.create!(created_at: (Statistics::RETENTION + 1.day).ago)

    Statistics.sweep_old!

    assert_equal [old_sign_in.id], Statistics::SignInEvent.pluck(:id)
  end
end
