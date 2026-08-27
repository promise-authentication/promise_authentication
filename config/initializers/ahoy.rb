class Ahoy::Store < Ahoy::DatabaseStore
  def authenticate(data)
    # disables automatic linking of visits and users
  end
end

# set to true for JavaScript tracking
Ahoy.api = true
Ahoy.mask_ips = true
Ahoy.cookies = false
# No geocoding: nothing reads the geo columns, and the lookups would send
# masked visitor IPs to ipinfo.io — over plain HTTP, keyless — making it a
# data processor for data we never use.
Ahoy.geocode = false
