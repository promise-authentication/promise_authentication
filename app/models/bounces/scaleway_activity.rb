# Asks Scaleway Transactional Email what became of the verification mail.
# Scaleway keeps an activity record per recipient, so the lookup goes by
# the address the user is waiting on (which Scaleway already holds, having
# sent to it) — we neither store it nor log it. Covers the failures the
# receiving server reports synchronously: unknown mailbox, mailbox full,
# rejected as spam or blocklisted.
module Bounces
  class ScalewayActivity
    CHECK_INTERVAL = 10.seconds
    BASE_URL = 'https://api.scaleway.com'.freeze

    # A non-2xx answer. Carries the status only: the request URL holds
    # the recipient's address, and the message must stay loggable.
    class ResponseError < StandardError
      attr_reader :status

      def initialize(status)
        @status = status
        super("Scaleway responded #{status}")
      end
    end

    def self.configured?
      ENV['SCALEWAY_TEM_SECRET_KEY'].present? && ENV['SCALEWAY_TEM_PROJECT_ID'].present?
    end

    # Throttled per code, since the page polls every few seconds.
    def self.check!(code, email:)
      return unless configured?
      return if code.delivery_checked_at && code.delivery_checked_at > CHECK_INTERVAL.ago

      code.update_column(:delivery_checked_at, Time.current)
      activity = new.latest_email_to(email, since: code.created_at - 1.minute)
      return unless activity && activity['status'] == 'failed'

      code.mark_bounced!(Reason.from_scaleway(activity) || Reason::OTHER)
    rescue ResponseError => e
      Rails.logger.warn "Scaleway activity check failed: #{e.message}"
      Airbrake.notify(e) if defined?(Airbrake)
      nil
    rescue StandardError => e
      Rails.logger.warn "Scaleway activity check failed: #{e.class}"
      Airbrake.notify(e) if defined?(Airbrake)
      nil
    end

    def latest_email_to(email, since:)
      response = connection.get(emails_path, {
                                  project_id: ENV.fetch('SCALEWAY_TEM_PROJECT_ID'),
                                  mail_rcpt: email,
                                  since: since.utc.iso8601,
                                  order_by: 'created_at_desc',
                                  page_size: 1
                                })
      raise ResponseError, response.status unless response.success?

      JSON.parse(response.body).fetch('emails', []).first
    end

    private

    def emails_path
      "/transactional-email/v1alpha1/regions/#{ENV.fetch('SCALEWAY_TEM_REGION', 'fr-par')}/emails"
    end

    def connection
      Faraday.new(
        url: BASE_URL,
        headers: { 'X-Auth-Token' => ENV.fetch('SCALEWAY_TEM_SECRET_KEY'), 'Accept' => 'application/json' },
        request: { timeout: 5, open_timeout: 3 }
      )
    end
  end
end
