Rails.configuration.to_prepare do
  Rails.configuration.jwt_private_key = OpenSSL::PKey::EC.new ENV['PROMISE_PRIVATE_KEY'].gsub("\\n", "\n")
  Rails.configuration.jwt_public_key = OpenSSL::PKey::EC.new ENV['PROMISE_PUBLIC_KEY'].gsub("\\n", "\n")
end
