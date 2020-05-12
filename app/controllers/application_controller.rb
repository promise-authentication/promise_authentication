class ApplicationController < ActionController::Base
  include LocaleConcern
  include AuthenticatedConcern
  include RelyingPartyConcern

  protect_from_forgery with: :reset_session
end
