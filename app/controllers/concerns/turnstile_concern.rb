module TurnstileConcern
  extend ActiveSupport::Concern

  class NotPassedError < RuntimeError; end

  included do
    helper_method :turnstile_tag_html
  end

  def turnstile_tag_html
    "<div class=\"cf-turnstile\" data-theme=\"light\" data-sitekey=\"#{ENV.fetch(
      'PROMISE_CLOUDFLARE_TURNSTILE_SITE_KEY', '3x00000000000000000000FF'
    )}\"></div>".html_safe
  end

  def pre_validated?
    !Rails.env.production? && params[:"cf-turnstile-response"].blank?
  end

  def token_is_valid?
    turnstile_token = params.fetch('cf-turnstile-response')

    # Now validate the token with the Turnstile service
    url = 'https://challenges.cloudflare.com/turnstile/v0/siteverify'
    turnstile_response = Faraday.post(url, {
                                        secret: ENV.fetch('PROMISE_CLOUDFLARE_TURNSTILE_SECRET_KEY',
                                                          '1x0000000000000000000000000000000AA'),
                                        response: turnstile_token
                                      })

    outcome = JSON.parse(turnstile_response.body)
    outcome['success'] == true
  end

  def turnstile_passed?
    return true if pre_validated?
    return true if token_is_valid?

    false
  end

  def pass_turnstile!
    return if turnstile_passed?

    raise TurnstileConcern::NotPassedError
  end
end
