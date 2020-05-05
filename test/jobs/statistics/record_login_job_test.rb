require 'test_helper'

class Statistics::RecordLoginJobTest < ActiveJob::TestCase
  test 'that it is done' do
    assert_enqueued_with(job: Statistics::RecordLoginJob) do
      Statistics::RecordLoginJob.perform_later( 'hello' )
    end
  end
end
