require 'test_helper'

class Bounces::ReasonTest < ActiveSupport::TestCase
  test 'enhanced status codes map to the categories the page explains' do
    assert_equal 'mailbox_not_found', Bounces::Reason.from_enhanced_status('5.1.1')
    assert_equal 'mailbox_not_found', Bounces::Reason.from_enhanced_status('5.4.4')
    assert_equal 'mailbox_full', Bounces::Reason.from_enhanced_status('5.2.2')
    assert_equal 'mailbox_full', Bounces::Reason.from_enhanced_status('4.2.2')
    assert_equal 'rejected', Bounces::Reason.from_enhanced_status('5.7.1')
    assert_equal 'rejected', Bounces::Reason.from_enhanced_status('5.2.1')
    assert_equal 'other', Bounces::Reason.from_enhanced_status('5.0.0')
    assert_equal 'other', Bounces::Reason.from_enhanced_status(nil)
  end

  test 'Scaleway flags win over the SMTP message' do
    email = { 'flags' => ['hard_bounce', 'mailbox_full'], 'last_tries' => [{ 'code' => 550, 'message' => '550 5.1.1 no such user' }] }
    assert_equal 'rejected', Bounces::Reason.from_scaleway(email)

    email = { 'flags' => [], 'last_tries' => [{ 'code' => 550, 'message' => '550 5.1.1 no such user' }] }
    assert_equal 'mailbox_not_found', Bounces::Reason.from_scaleway(email)

    assert_equal 'other', Bounces::Reason.from_scaleway({})
  end
end
