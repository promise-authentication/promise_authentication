require 'test_helper'

class Bounces::ScalewayActivityTest < ActiveSupport::TestCase
  EMAILS_URL = 'https://api.scaleway.com/transactional-email/v1alpha1/regions/fr-par/emails'.freeze

  setup do
    @code = EmailVerificationCode.create!(id: Authentication::HashedEmail.from_cleartext('hello@world.com'), code: 'ab7k')
    @env = ENV.slice('SCALEWAY_TEM_SECRET_KEY', 'SCALEWAY_TEM_PROJECT_ID')
    ENV['SCALEWAY_TEM_SECRET_KEY'] = 'secret'
    ENV['SCALEWAY_TEM_PROJECT_ID'] = 'project'
  end

  teardown do
    ENV.delete('SCALEWAY_TEM_SECRET_KEY')
    ENV.delete('SCALEWAY_TEM_PROJECT_ID')
    ENV.update(@env)
  end

  def stub_activity(emails)
    stub_request(:get, EMAILS_URL)
      .with(query: hash_including('mail_rcpt' => 'hello@world.com', 'project_id' => 'project', 'order_by' => 'created_at_desc'),
            headers: { 'X-Auth-Token' => 'secret' })
      .to_return(status: 200, body: { emails: emails }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  test 'a failed email marks the code bounced with the flagged reason' do
    stub = stub_activity([{ 'status' => 'failed', 'flags' => ['mailbox_not_found'], 'last_tries' => [{ 'code' => 550, 'message' => '550 5.1.1 nope' }] }])

    Bounces::ScalewayActivity.check!(@code, email: 'hello@world.com')

    assert_requested stub
    assert @code.reload.bounced?
    assert_equal 'mailbox_not_found', @code.bounce_reason
  end

  test 'a sent email leaves the code alone but records the check' do
    stub_activity([{ 'status' => 'sent', 'flags' => [] }])

    Bounces::ScalewayActivity.check!(@code, email: 'hello@world.com')

    assert_not @code.reload.bounced?
    assert @code.delivery_checked_at
  end

  test 'checks are throttled per code' do
    stub = stub_activity([])
    Bounces::ScalewayActivity.check!(@code, email: 'hello@world.com')
    Bounces::ScalewayActivity.check!(@code, email: 'hello@world.com')
    assert_requested stub, times: 1
  end

  test 'a provider error is swallowed' do
    stub_request(:get, EMAILS_URL).with(query: hash_including({})).to_return(status: 500, body: 'nope')
    assert_nothing_raised { Bounces::ScalewayActivity.check!(@code, email: 'hello@world.com') }
    assert_not @code.reload.bounced?
  end

  test 'nothing happens without credentials' do
    ENV.delete('SCALEWAY_TEM_SECRET_KEY')
    Bounces::ScalewayActivity.check!(@code, email: 'hello@world.com')
    assert_nil @code.reload.delivery_checked_at
  end
end
