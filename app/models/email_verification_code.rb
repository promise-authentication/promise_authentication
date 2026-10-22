class EmailVerificationCode < ApplicationRecord
  # Codes and magic links share this lifetime, so the whole verification
  # mail expires at once — never a dead link next to a working code.
  TTL = 1.hour

  module HumanReadableCode
    ALPHABET = 'abcdefghkmnpqrstuvwxyz23456789'.freeze
    def self.generate(range)
      # The length should be a random number in the range
      length = range.to_a.sample(1, random: SecureRandom).first
      # The code should be a random string of the given length
      # sampled from the alphabet
      Array.new(length) { ALPHABET.chars.sample(1, random: SecureRandom).first }.join
    end
  end

  def self.find_by_cleartext(email)
    hashed = Authentication::HashedEmail.from_cleartext(email)

    find(hashed)
  rescue ActiveRecord::RecordNotFound
    return nil
  end

  # Like find_by_cleartext, but treats expired codes as absent.
  # Use this everywhere a code is checked or displayed; the raw
  # find_by_cleartext remains for cleanup.
  def self.active_for_cleartext(email)
    code = find_by_cleartext(email)
    return nil if code.nil? || code.expired?

    code
  end

  def self.sweep_expired!
    where('created_at < ?', TTL.ago).delete_all
  end

  def expired?
    created_at < TTL.ago
  end

  # --- bounce tracking (see Bounces) ---------------------------------

  BOUNCE_REASONS = Bounces::Reason::ALL

  def bounced?
    bounced_at.present?
  end

  # The mail provably never landed, as opposed to a rejection somewhere
  # down a forwarding chain where the first mailbox may well hold it.
  def mail_certainly_undelivered?
    bounced? && [Bounces::Reason::MAILBOX_NOT_FOUND, Bounces::Reason::MAILBOX_FULL].include?(bounce_reason)
  end

  def mark_bounced!(reason)
    return if bounced?

    reason = Bounces::Reason::OTHER unless BOUNCE_REASONS.include?(reason)
    update!(bounced_at: Time.current, bounce_reason: reason)
    Rails.logger.info "Verification mail bounced (#{reason})"
  end

  # Matches a parsed delivery report to a pending code. The token in the
  # mail's own headers is authoritative: when the report carries one that
  # no longer matches, the code it was about is gone and the report is
  # moot. Only reports without a token fall back to the hashed recipient.
  def self.record_bounce!(report)
    code = if report.token
             find_by(delivery_token: report.token)
           elsif report.recipient_hashes.any?
             where(id: report.recipient_hashes).order(created_at: :desc).first
           end
    return nil if code.nil? || code.expired?

    code.mark_bounced!(report.reason)
    code
  end
end
