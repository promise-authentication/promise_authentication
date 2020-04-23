class Authentication::RelyingParty
  include ActiveModel::Model

  attr_accessor :id, :name, :logo_url, :locale
  attr_accessor :legacy_account_authentication_url, :legacy_account_forgot_password_url

  validates :legacy_account_authentication_url, format: { with: /\Ahttps/ }, allow_nil: true

  def self.find(id)
    return nil if id.blank?

    url = "https://#{id}/.well-known/promise.json"

    well_knowns = begin
                    JSON.parse(HTTParty.get(url).body)
                  rescue JSON::ParserError, SocketError, URI::InvalidURIError, OpenSSL::SSL::SSLError
                    {}
                  end

    new(well_knowns.merge({id: id}))
  end

  def supports_legacy_accounts?
    legacy_account_authentication_url.present? &&
      legacy_account_forgot_password_url.present?
  end

  def knows_legacy_account?(email)
    false
  end

  def legacy_account_user_id_for(email, password)
    return nil unless supports_legacy_accounts?
    return nil unless valid?

    response = HTTParty.get(legacy_account_authentication_url, query: {
      email: CGI.escape(email),
      password: CGI.escape(password)
    })

    return nil if response&.code != 200

    JSON.parse(response.body)['user_id']
  end

  def name
    @name || id
  end

  def redirect_url(id_token:, login_configuration:)
    "https://#{id}/authenticate?id_token=#{id_token}"
  end
end
