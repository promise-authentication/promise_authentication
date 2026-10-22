# Finds out whether the verification mail a user is waiting for bounced,
# so the verify_email page can say so instead of letting them stare at an
# inbox that will never fill. Two sources:
#
# * Bounces::ScalewayActivity — rejections our SMTP provider (Scaleway
#   TEM) saw itself: mailbox full, unknown user, blocklisted. Looked up
#   from the status poll.
# * Bounces::Mailbox — asynchronous non-delivery reports that arrive by
#   mail. Mail goes out with the envelope sender set to the bounce address
#   (PROMISE_BOUNCE_ADDRESS), so e.g. a forwarding mailbox that failed to
#   pass the mail on sends its report there, and we read it over IMAP.
#
# Everything here keeps the no-personal-data promise: codes carry an
# opaque delivery token to match reports on, reports are matched by the
# hashed address as a fallback, and only a short reason category is
# stored — never an address, never the provider's message.
module Bounces
  TOKEN_HEADER = 'X-Promise-Verification'.freeze

  # Envelope sender (Return-Path) for verification mails. Unset → the
  # From address, i.e. hello@, which is forwarded to a human mailbox.
  def self.return_path
    ENV['PROMISE_BOUNCE_ADDRESS'].presence
  end

  # Called from the verify_email status poll. Runs every source that is
  # configured; failures are logged (without addresses) and swallowed, so
  # a flaky provider never breaks the poll.
  def self.detect!(code, email:)
    return code if code.bounced?

    ScalewayActivity.check!(code, email: email)
    Mailbox.poll_if_due!
    code.reload
  end
end
