class Trust::KeyPair < ActiveResource::Base
  self.site = ENV['PROMISE_KEY_REGISTRY_API_ROOT']
end
