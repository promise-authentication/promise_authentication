class Authentication::RelyingParty
  class InvalidRedirectUri < Exception; end

  include ActiveModel::Model

  attr_accessor :id, :name, :logo_url, :locale
  attr_accessor :admin_user_ids
  attr_accessor :legacy_account_authentication_url, :legacy_account_forgot_password_url

  validates :legacy_account_authentication_url, format: { with: /\Ahttps/ }, allow_nil: true

  def self.find(id)
    return nil if id.blank?

    new(well_knowns(well_known_url(id)).merge({id: id}))
  end

  def self.well_known_url(id)
    "https://#{id}/.well-known/promise.json"
  end

  def self.well_knowns(url)
    response = fetch(url)
    body = response&.body || ''
    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end

  def well_knowns
    self.class.well_knowns(well_known_url)
  end

  def http_headers
    self.class.fetch(well_known_url)&.headers
  end

  def well_known_url
    self.class.well_known_url(id)
  end

  def administratable?(user_id)
    admin_user_ids&.include?(user_id)
  end

  def self.fetch(url)
    client = Faraday.new do |builder|
      builder.use :http_cache, store: Rails.cache, logger: Rails.logger, serializer: Marshal
      builder.adapter Faraday.default_adapter
    end
    response = client.get(url)
    response
  rescue Faraday::SSLError, Faraday::ConnectionFailed
    nil
  end

  def logo_data
    return nil unless logo_url.present?

    response = self.class.fetch(logo_url)
    return nil if response&.status != 200

    content_type = response.headers['content-type']
    base64 = Base64.strict_encode64(response.body)
    return "data:#{content_type};base64,#{base64}"
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

    response = self.class.fetch(legacy_account_authentication_url, query: {
      email: email,
      password: password
    })

    return nil if response&.code != 200

    JSON.parse(response.body)['user_id']
  end

  def name
    @name || id
  end

  def name_html
    name.gsub(' ', '&nbsp').html_safe
  end

  def redirect_uri(id_token:, login_configuration:)
    if login_configuration[:redirect_uri].present?
      uri = URI.parse(login_configuration[:redirect_uri])
      if uri.host == id
        new_query_ar = URI.decode_www_form(uri.query || '') << ['id_token', id_token]
        uri.query = URI.encode_www_form(new_query_ar)
        uri.to_s
      else
        raise InvalidRedirectUri.new(login_configuration[:redirect_uri])
      end
    else
      "https://#{id}/authenticate?id_token=#{id_token}"
    end
  end
end
