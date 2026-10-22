require 'net/imap'

# Reads delivery reports from the bounce mailbox over IMAP and marks the
# codes they belong to. The mailbox must be dedicated to bounces: every
# report is deleted once read (matched or not — an unmatched report is
# about a code that already expired or finished, and still holds an
# address we promised not to keep). Anything that is not a report is
# left in place and marked seen, so it is never read twice.
module Bounces
  class Mailbox
    POLL_INTERVAL = 30.seconds
    TIMEOUT = 10.seconds

    def self.configured?
      %w[PROMISE_BOUNCE_IMAP_HOST PROMISE_BOUNCE_IMAP_USERNAME PROMISE_BOUNCE_IMAP_PASSWORD]
        .all? { |name| ENV[name].present? }
    end

    # Reports arrive within a minute of sending, while the user is still
    # on the verify_email page, so the page's status poll reads the
    # mailbox — at most once per POLL_INTERVAL across all users, which
    # also protects the mailbox from being hammered. (The cache is per
    # process; a few processes means a few polls per interval. Fine.)
    def self.poll_if_due!
      return unless configured?
      return unless Rails.cache.write('bounces/mailbox/polled', true, unless_exist: true, expires_in: POLL_INTERVAL)

      poll!
    end

    # Returns { reports:, matched: } counts, or nil when not configured.
    def self.poll!
      return nil unless configured?

      Timeout.timeout(TIMEOUT) { new.poll! }
    rescue StandardError => e
      Rails.logger.warn "Bounce mailbox poll failed: #{e.class}"
      Airbrake.notify(e) if defined?(Airbrake)
      nil
    end

    def initialize(client: nil)
      @client = client
    end

    def poll!
      imap = @client || connect!
      imap.select('INBOX')
      counts = { reports: 0, matched: 0 }

      imap.search(['UNSEEN']).each do |sequence|
        raw = imap.fetch(sequence, 'BODY.PEEK[]')&.first&.attr&.fetch('BODY[]', nil)
        report = Report.parse(raw)

        if report
          counts[:reports] += 1
          counts[:matched] += 1 if EmailVerificationCode.record_bounce!(report)
          imap.store(sequence, '+FLAGS', [:Deleted])
        else
          imap.store(sequence, '+FLAGS', [:Seen])
        end
      end

      imap.expunge
      Rails.logger.info "Bounce mailbox: #{counts[:reports]} reports, #{counts[:matched]} matched a pending code"
      counts
    ensure
      if imap && @client.nil?
        begin
          imap.logout
        rescue StandardError
          nil
        end
        imap.disconnect
      end
    end

    private

    def connect!
      imap = Net::IMAP.new(
        ENV.fetch('PROMISE_BOUNCE_IMAP_HOST'),
        port: ENV.fetch('PROMISE_BOUNCE_IMAP_PORT', 993).to_i,
        ssl: true,
        open_timeout: 5
      )
      imap.login(ENV.fetch('PROMISE_BOUNCE_IMAP_USERNAME'), ENV.fetch('PROMISE_BOUNCE_IMAP_PASSWORD'))
      imap
    end
  end
end
