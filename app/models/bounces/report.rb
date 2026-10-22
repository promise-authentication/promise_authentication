# A non-delivery report (RFC 3464 "DSN", or the looser variants some
# mail servers send) parsed just far enough to find the verification
# code it is about. Nothing from the report is kept beyond the result.
module Bounces
  class Report
    attr_reader :token, :recipient_hashes, :reason, :enhanced_status

    # Returns nil for mail that is not a delivery report (auto-replies,
    # humans writing to the bounce address) so those can never flag a
    # code as bounced.
    def self.parse(raw)
      mail = Mail.new(raw.to_s)
      return nil unless delivery_report?(mail)

      new(raw.to_s, mail)
    rescue StandardError => e
      Rails.logger.warn "Bounce report could not be parsed: #{e.class}"
      nil
    end

    REPORT_SUBJECT = /undeliver|delivery (status|failure|report)|returned mail|could not be delivered|
                      couldn't be delivered|mail delivery failed|kunne ikke leveres|failure notice/ix
    REPORT_SENDER = /mailer-daemon|postmaster|microsoftexchange/i

    def self.delivery_report?(mail)
      return true if mail.mime_type == 'multipart/report'
      return true if mail.all_parts.any? { |part| part.mime_type == 'message/delivery-status' }
      return true if mail.from.to_a.any? { |address| address =~ REPORT_SENDER }

      mail.subject.to_s =~ REPORT_SUBJECT ? true : false
    end

    TOKEN_LINE = /^#{Regexp.escape(Bounces::TOKEN_HEADER)}:[ \t]*([A-Za-z0-9_-]{16,})/i
    ADDRESS = /[A-Za-z0-9._%+'-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/
    DSN_STATUS_LINE = /^Status:[ \t]*([245]\.\d{1,3}\.\d{1,3})/i

    # Scans the raw text as received (re-encoding would invent headers)
    # plus every part decoded, so a base64-attached original is read too.
    def initialize(raw, mail)
      texts = [raw] + mail.all_parts.map { |part| safely_decoded(part) }.compact
      @token = texts.filter_map { |text| text[TOKEN_LINE, 1] }.first
      @recipient_hashes = texts.flat_map { |text| text.scan(ADDRESS) }
                               .map(&:downcase).uniq
                               .reject { |address| ours?(address) }
                               .map { |address| Authentication::HashedEmail.from_cleartext(address) }
      @enhanced_status = texts.filter_map { |text| text[DSN_STATUS_LINE, 1] }.first ||
                         texts.filter_map { |text| Reason.enhanced_status_in(text) }.first
      @reason = Reason.from_enhanced_status(@enhanced_status)
    end

    private

    def safely_decoded(part)
      part.decoded.to_s
    rescue StandardError
      nil
    end

    OUR_DOMAINS = %w[promiseauthentication.org].freeze
    SYSTEM_LOCAL_PARTS = %w[mailer-daemon postmaster].freeze

    # Our own and the reporting server's addresses appear in every
    # report; only the recipient's can lead to a code.
    def ours?(address)
      local, domain = address.split('@', 2)
      OUR_DOMAINS.include?(domain) || SYSTEM_LOCAL_PARTS.include?(local) ||
        (Bounces.return_path && address == Bounces.return_path.downcase)
    end
  end
end
