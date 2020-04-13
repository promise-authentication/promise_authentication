class Authentication::RelyingParty
  include ActiveModel::Model

  attr_accessor :id, :name, :logo_url

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
end
