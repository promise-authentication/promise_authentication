module RelyingPartyConcern
  extend ActiveSupport::Concern

  included do
    helper_method :relying_party
    helper_method :custom_scheme_handoff?
    helper_method :mobile_device?
  end

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:client_id])
  end

  # True when the final redirect hands the id_token to a native app via a
  # custom URL scheme (e.g. oase://authenticate) rather than the web. Such
  # a redirect only works on a device with the app installed — a desktop
  # browser silently refuses it ("unknown protocol").
  def custom_scheme_handoff?
    # No redirect_uri param means the party's default_redirect_uri, which
    # is always https — only an explicit param can name a custom scheme.
    url = login_configuration[:redirect_uri]
    return false if url.blank?

    scheme = URI.parse(url).scheme
    scheme.present? && !%w[http https].include?(scheme)
  rescue URI::InvalidURIError
    false
  end

  # Coarse on purpose: only used to pick copy/affordances for handoffs the
  # current device plainly cannot perform. iPads in desktop mode report a
  # Mac user agent and get the desktop treatment — acceptable.
  def mobile_device?
    request.user_agent.to_s.match?(/iPhone|iPad|iPod|Android/i)
  end
end
