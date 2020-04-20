class Authentication::RelyingParty
  include ActiveModel::Model

  attr_accessor :id, :name, :logo_url, :locale

  def self.find(id)
    return nil if id.blank?

    url = "https://#{id}/.well-known/authentication.json"

    well_knowns = begin
                    JSON.parse(HTTParty.get(url).body)
                  rescue JSON::ParserError, SocketError, URI::InvalidURIError, OpenSSL::SSL::SSLError
                    {}
                  end

    new(well_knowns.merge({id: id}))
  end

  def name
    @name || id
  end

  def redirect_url(id_token:, login_configuration:)
    "https://#{id}/authenticate?id_token=#{id_token}"
  end
end
