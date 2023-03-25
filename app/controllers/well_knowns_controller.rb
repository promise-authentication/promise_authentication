class WellKnownsController < ApplicationController

  def jwks
    @keys = Trust::Certificate.unexpired.map do |cert|
      cert.public_key.to_jwk(alg: 'ES512')
    end
  end

end
