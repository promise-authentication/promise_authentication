# Our logs are drained to Papertrail, so the privacy policy (/privacy)
# promises that logs we write mask IP addresses the same way Ahoy masks
# them for statistics. Heroku's router logs still carry the full client
# IP (fwd=...) — that's platform-generated and out of our hands, and the
# policy says so.
require 'rails/rack/logger'

module MaskedRequestLog
  private

  def started_request_message(request)
    ip = begin
      Ahoy.mask_ip(request.remote_ip)
    rescue IPAddr::InvalidAddressError
      request.remote_ip
    end

    sprintf('Started %s "%s" for %s at %s',
            request.raw_request_method,
            request.filtered_path,
            ip,
            Time.now)
  end
end

Rails::Rack::Logger.prepend(MaskedRequestLog)
