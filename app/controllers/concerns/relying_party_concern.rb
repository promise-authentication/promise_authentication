module RelyingPartyConcern
  extend ActiveSupport::Concern

  included do
    helper_method :relying_party
  end

  def relying_party
    @relying_party ||= ::Authentication::RelyingParty.find(params[:client_id])
  end
end
