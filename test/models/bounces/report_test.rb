require 'test_helper'

class Bounces::ReportTest < ActiveSupport::TestCase
  def fixture(name)
    file_fixture("bounces/#{name}.eml").read
  end

  test 'an Office 365 report for a failed forward carries our token and the policy reason' do
    report = Bounces::Report.parse(fixture('office365_forward_rejected'))

    assert report
    assert_equal 'tok_office365_abcdefghijklmnopqrstuv', report.token
    assert_equal '5.7.1', report.enhanced_status
    assert_equal Bounces::Reason::REJECTED, report.reason
    # Both the original recipient and the forwardee show up — hashed,
    # never the addresses themselves.
    assert_includes report.recipient_hashes, Authentication::HashedEmail.from_cleartext('scout@ryds.example')
    assert_includes report.recipient_hashes, Authentication::HashedEmail.from_cleartext('forwardee@gmail.example')
    assert_not_includes report.recipient_hashes, Authentication::HashedEmail.from_cleartext('hello@promiseauthentication.org')
    assert_not_includes report.recipient_hashes, Authentication::HashedEmail.from_cleartext('bounces@promiseauthentication.org')
  end

  test 'a report without our header falls back to the recipient and reads the DSN status' do
    report = Bounces::Report.parse(fixture('mailbox_not_found_no_token'))

    assert report
    assert_nil report.token
    assert_equal '5.1.1', report.enhanced_status
    assert_equal Bounces::Reason::MAILBOX_NOT_FOUND, report.reason
    assert_equal [Authentication::HashedEmail.from_cleartext('nobody@typo.example')], report.recipient_hashes
  end

  test 'a base64-attached original still yields the token' do
    report = Bounces::Report.parse(fixture('base64_attached_original'))

    assert report
    assert_equal 'tok_base64_abcdefghijklmnopqrstuv', report.token
    assert_equal Bounces::Reason::MAILBOX_FULL, report.reason
  end

  test 'an out-of-office reply is not a report' do
    assert_nil Bounces::Report.parse(fixture('out_of_office'))
  end

  test 'garbage is not a report' do
    assert_nil Bounces::Report.parse('')
    assert_nil Bounces::Report.parse("Subject: hi\n\nhello")
  end
end
