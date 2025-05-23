class Authentication::RelyingParty
  class InvalidRedirectUri < Exception; end

  include ActiveModel::Model

  attr_accessor :id, :name, :logo_url, :locale, :allowed_redirect_domain_names, :allowed_redirect_uris,
                :admin_user_ids, :legacy_account_authentication_url, :legacy_account_forgot_password_url

  validates :legacy_account_authentication_url, format: { with: /\Ahttps/ }, allow_nil: true

  def self.find(id)
    return nil if id.blank?

    new(well_knowns(well_known_url(id)).merge({ id: id }))
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

  def secret_key_base64
    message = ENV['PROMISE_RELYING_PARTY_KEY_SALT'] + id
    Base64.strict_encode64 RbNaCl::Hash.sha256(message)
  end

  def self.http_client
    Faraday.new do |builder|
      builder.use :http_cache, store: Rails.cache, logger: Rails.logger, serializer: Marshal
      builder.use FaradayMiddleware::FollowRedirects
      builder.adapter Faraday.default_adapter
    end
  end

  def self.fetch(url)
    http_client.get(url)
  rescue Faraday::SSLError, Faraday::ConnectionFailed
    nil
  end

  def self.head(url)
    http_client.head(url)
  rescue Faraday::SSLError, Faraday::ConnectionFailed
    nil
  end

  def logo_data
    return nil unless logo_url.present?

    head = self.class.head(logo_url)
    size = head.headers['content-length'].to_i
    return nil if size.zero?
    return nil if size >= 1_048_576 # 1MB

    mime = head.headers['content-type']
    return nil unless mime.start_with?('image/')

    response = self.class.fetch(logo_url)

    return nil if response&.status != 200
    return nil if response&.headers&.[]('content-type') != mime
    return nil if response&.headers&.[]('content-length').to_i != size
    return nil if response&.body&.bytesize != size

    base64 = Base64.strict_encode64(response.body)
    "data:#{mime};base64,#{base64}"
  end

  def supports_legacy_accounts?
    legacy_account_authentication_url.present? &&
      legacy_account_forgot_password_url.present?
  end

  def knows_legacy_account?(_email)
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

  def local_hosts
    ['127.0.0.1', /localhost$/]
  end

  def included?(array, value)
    array.each do |str_or_reg|
      if str_or_reg.is_a?(String)
        return true if str_or_reg == value
      elsif str_or_reg.match?(value)
        return true
      end
    end
    false
  end

  def local_host?(uri)
    included?(local_hosts, uri.host)
  end

  def allowed_redirect_domain_names
    ((@allowed_redirect_domain_names || []) + [id] + local_hosts)
  end

  def allowed_redirect_host?(uri)
    included?(allowed_redirect_domain_names, uri.host)
  end

  def allowed_scheme?(uri)
    allowed_schemes = ['https']
    allowed_schemes << 'http' if local_host?(uri)
    allowed_schemes.include?(uri.scheme)
  end

  def name_html
    name.gsub(' ', '&nbsp').html_safe
  end

  def default_redirect_uri
    "https://#{id}/authenticate"
  end

  def allowed_uri?(uri)
    @allowed_redirect_uris&.include?(uri.to_s.split('?').first)
  end

  def redirect_uri(id_token:, login_configuration:)
    url = login_configuration[:redirect_uri] || default_redirect_uri
    uri = URI.parse(url)

    raise InvalidRedirectUri.new(url) unless allowed_uri?(uri) || (allowed_scheme?(uri) && allowed_redirect_host?(uri))

    new_query_ar = URI.decode_www_form(uri.query || '') << ['id_token', id_token]
    uri.query = URI.encode_www_form(new_query_ar)
    uri.to_s
  end
end
