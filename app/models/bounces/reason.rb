# Reduces what a mail server told us to one of a few categories the
# verify_email page can explain. The categories are deliberately coarse:
# they decide which sentence the user reads and whether the code entry
# still makes sense, nothing more.
module Bounces
  module Reason
    MAILBOX_NOT_FOUND = 'mailbox_not_found'.freeze
    MAILBOX_FULL = 'mailbox_full'.freeze
    REJECTED = 'rejected'.freeze
    OTHER = 'other'.freeze
    ALL = [MAILBOX_NOT_FOUND, MAILBOX_FULL, REJECTED, OTHER].freeze

    # Scaleway's own categorisation of a failed email, see the `flags` on
    # https://www.scaleway.com/en/developers/api/transactional-email/
    FLAGS = {
      'mailbox_not_found' => MAILBOX_NOT_FOUND,
      'mailbox_full' => MAILBOX_FULL,
      'spam' => REJECTED,
      'blocklisted' => REJECTED,
      'hard_bounce' => REJECTED
    }.freeze

    # RFC 3463 enhanced status code (e.g. "5.1.1") → category.
    def self.from_enhanced_status(status)
      return OTHER if status.blank?

      _klass, subject, detail = status.split('.')
      case [subject, detail]
      in ['1', _] | ['4', '4'] then MAILBOX_NOT_FOUND
      in ['2', '2'] | ['3', '1'] then MAILBOX_FULL
      in ['7', _] | ['2', '1'] then REJECTED
      else OTHER
      end
    end

    def self.from_flags(flags)
      Array(flags).map { |flag| FLAGS[flag.to_s] }.compact.first
    end

    # For a Scaleway email object: flags first, then the enhanced status
    # in the last delivery attempt's SMTP message.
    def self.from_scaleway(email)
      from_flags(email['flags']) ||
        from_enhanced_status(enhanced_status_in(Array(email['last_tries']).last.to_h['message']))
    end

    ENHANCED_STATUS = /\b([245]\.\d{1,3}\.\d{1,3})\b/

    def self.enhanced_status_in(text)
      text.to_s[ENHANCED_STATUS, 1]
    end
  end
end
