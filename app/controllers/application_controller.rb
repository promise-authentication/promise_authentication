class ApplicationController < ActionController::Base
  include LocaleConcern
  include AuthenticatedConcern
  include RelyingPartyConcern
  include TurnstileConcern
  include BackToConcern

  protect_from_forgery with: :reset_session

  private

  # Sign-in funnel event (see Root::FunnelController), name + relying
  # party only — never the email or any other PII, like registration_step.
  def track_sign_in_step(step, **properties)
    ahoy.track 'sign_in_step', { step: step, relying_party_id: relying_party&.id }.merge(properties)
  end
end
