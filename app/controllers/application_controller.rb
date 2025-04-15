class ApplicationController < ActionController::Base
  include LocaleConcern
  include AuthenticatedConcern
  include RelyingPartyConcern
  include TurnstileConcern

  protect_from_forgery with: :reset_session
end
