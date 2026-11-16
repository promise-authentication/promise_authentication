require 'test_helper'
require 'net/imap'

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

  IMAP_ENV = {
    'PROMISE_BOUNCE_IMAP_HOST' => 'imap.example',
    'PROMISE_BOUNCE_IMAP_USERNAME' => 'bounces',
    'PROMISE_BOUNCE_IMAP_PASSWORD' => 'secret'
  }.freeze

  def with_imap_env
    old = ENV.slice(*IMAP_ENV.keys, 'PROMISE_BOUNCE_IMAP_PORT')
    ENV.update(IMAP_ENV)
    yield
  ensure
    (IMAP_ENV.keys + ['PROMISE_BOUNCE_IMAP_PORT']).each { |name| ENV.delete(name) }
    ENV.update(old)
  end

  # FakeImap plus the connection lifecycle the poll owns when it connects itself.
  class ConnectingImap < FakeImap
    attr_reader :logged_in_as, :logged_out, :disconnected

    def initialize(messages, logout_fails: false)
      super(messages)
      @logout_fails = logout_fails
    end

    def login(user, password) = @logged_in_as = [user, password]

    def logout
      raise Net::IMAP::ByeResponseError, 'bye' if @logout_fails

      @logged_out = true
    end

    def disconnect = @disconnected = true
  end

  test 'poll! connects over IMAPS with the configured account and logs out again' do
    imap = ConnectingImap.new([fixture('out_of_office')])
    connected_with = nil
    new_imap = lambda do |host, **options|
      connected_with = [host, options]
      imap
    end

    with_imap_env do
      Net::IMAP.stub :new, new_imap do
        assert_equal({ reports: 0, matched: 0 }, Bounces::Mailbox.poll!)
      end
    end

    assert_equal ['imap.example', { port: 993, ssl: true, open_timeout: 5 }], connected_with
    assert_equal %w[bounces secret], imap.logged_in_as
    assert imap.logged_out
    assert imap.disconnected
  end

  test 'a failing logout still disconnects' do
    imap = ConnectingImap.new([], logout_fails: true)

    with_imap_env do
      Net::IMAP.stub :new, ->(*, **) { imap } do
        Bounces::Mailbox.poll!
      end
    end

    assert imap.disconnected
  end

  test 'a failing poll is logged and reported, not raised' do
    logged = []
    notified = []

    with_imap_env do
      Net::IMAP.stub :new, ->(*, **) { raise Errno::ECONNREFUSED } do
        Rails.logger.stub :warn, ->(line) { logged << line } do
          Airbrake.stub :notify, ->(error) { notified << error } do
            assert_nil Bounces::Mailbox.poll!
          end
        end
      end
    end

    assert_equal ['Bounce mailbox poll failed: Errno::ECONNREFUSED'], logged
    assert_instance_of Errno::ECONNREFUSED, notified.first
  end

  test 'poll_if_due! polls at most once per interval' do
    polls = 0

    Rails.stub :cache, ActiveSupport::Cache::MemoryStore.new do
      Bounces::Mailbox.stub :poll!, -> { polls += 1 } do
        Bounces::Mailbox.poll_if_due!
        with_imap_env do
          Bounces::Mailbox.poll_if_due!
          Bounces::Mailbox.poll_if_due!
        end
      end
    end

    assert_equal 1, polls, 'not configured: no poll; configured: one poll per interval'
  end
end
