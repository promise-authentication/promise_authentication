require 'test_helper'

class Bounces::MailboxTest < ActiveSupport::TestCase
  # Just enough of Net::IMAP for the poll: a list of raw messages, and a
  # record of the flags stored against each.
  class FakeImap
    attr_reader :flags, :expunged

    def initialize(messages)
      @messages = messages
      @flags = Hash.new { |h, k| h[k] = [] }
      @expunged = false
    end

    def select(_mailbox); end
    def search(_criteria) = (1..@messages.size).to_a
    FetchData = Struct.new(:attr)
    def fetch(sequence, _attr) = [FetchData.new({ 'BODY[]' => @messages[sequence - 1] })]
    def store(sequence, _op, flags) = @flags[sequence].concat(flags)
    def expunge = @expunged = true
  end

  def fixture(name)
    file_fixture("bounces/#{name}.eml").read
  end

  test 'reports are matched, then deleted; other mail is marked seen' do
    code = EmailVerificationCode.create!(
      id: Authentication::HashedEmail.from_cleartext('scout@ryds.example'),
      code: 'ab7k', delivery_token: 'tok_office365_abcdefghijklmnopqrstuv'
    )
    imap = FakeImap.new([fixture('office365_forward_rejected'), fixture('out_of_office'), fixture('mailbox_not_found_no_token')])

    counts = Bounces::Mailbox.new(client: imap).poll!

    assert_equal({ reports: 2, matched: 1 }, counts)
    assert_equal [:Deleted], imap.flags[1]
    assert_equal [:Seen], imap.flags[2]
    assert_equal [:Deleted], imap.flags[3], 'an unmatched report still holds an address and goes too'
    assert imap.expunged

    code.reload
    assert code.bounced?
    assert_equal 'rejected', code.bounce_reason
  end

  test 'poll! is a no-op without IMAP configuration' do
    assert_nil Bounces::Mailbox.poll!
  end
end
