class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # disables automatic linking of visits and users
  end
end

# set to true for JavaScript tracking
Ahoy.api = true
Ahoy.mask_ips = true
Ahoy.cookies = false
# The geocode job enqueues to RabbitMQ, which the test env doesn't run —
# a request with a real-browser user agent would 500 on visit creation.
Ahoy.geocode = false if Rails.env.test?
