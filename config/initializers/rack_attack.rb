Rack::Attack.throttle("authentication/ip", limit: 20, period: 1.minute) do |req|
  req.ip if req.path == "/authenticate" && req.post?
end

Rack::Attack.throttle("authentication/email", limit: 10, period: 1.minute) do |req|
  req.params["email"].to_s.downcase.strip if req.path == "/authenticate" && req.post?
end

Rack::Attack.throttle("password_recovery/ip", limit: 5, period: 1.minute) do |req|
  req.ip if req.path == "/password/recover" && req.post?
end

Rack::Attack.throttle("password_recovery/email", limit: 3, period: 10.minutes) do |req|
  req.params["email"].to_s.downcase.strip if req.path == "/password/recover" && req.post?
end

Rack::Attack.throttle("email_verification/ip", limit: 10, period: 1.minute) do |req|
  req.ip if req.path == "/registrations/verify_email" && req.post?
end

Rack::Attack.throttle("registrations/ip", limit: 10, period: 1.minute) do |req|
  req.ip if req.path == "/registrations" && req.post?
end

Rack::Attack.throttled_responder = lambda do |_env|
  html = Rails.public_path.join("429.html").read
  [429, { "Content-Type" => "text/html" }, [html]]
end
