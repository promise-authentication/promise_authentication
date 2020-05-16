class WellKnownsController < ApplicationController

  def jwks
    @keys = Trust::Certificate.unexpired.map do |cert|
      cert.public_key.to_jwk
    end
  end

end
