# Development convenience: a local stand-in for the external Key Registry
# (KMS). When no PROMISE_KEY_REGISTRY_API_ROOT is configured in development,
# back Trust::KeyPair with an on-disk keypair store so the full sign-up,
# login and recovery flow works locally without running a separate KMS.
#
# It is enabled ONLY in development and ONLY when no KMS URL is set, so
# pointing at a real KMS (or running in test/production) is unaffected.
if Rails.env.development? && ENV['PROMISE_KEY_REGISTRY_API_ROOT'].blank?
  require 'ostruct'

  module DevKeyRegistry
    STORE = Rails.root.join('tmp', 'dev_key_registry.json')

    module_function

    def store
      File.exist?(STORE) ? JSON.parse(File.read(STORE)) : {}
    end

    def save(data)
      File.write(STORE, JSON.generate(data))
    end

    # Mirrors the KMS: generates an off-site keypair, persists the private key
    # keyed by its public key, and returns only the public key.
    def create
      private_key = RbNaCl::PrivateKey.generate
      public_key_base64 = Base64.strict_encode64(private_key.public_key.to_bytes)

      data = store
      data[public_key_base64] = Base64.strict_encode64(private_key.to_bytes)
      save(data)

      OpenStruct.new(public_key: public_key_base64)
    end

    def find(public_key_base64)
      private_key_base64 = store[public_key_base64]
      raise ActiveResource::ResourceNotFound.new(nil, "no dev key for #{public_key_base64}") if private_key_base64.nil?

      OpenStruct.new(public_key: public_key_base64, private_key: private_key_base64)
    end
  end

  Rails.application.config.to_prepare do
    Trust::KeyPair.define_singleton_method(:create) { |*| DevKeyRegistry.create }
    Trust::KeyPair.define_singleton_method(:find) { |id, *| DevKeyRegistry.find(id) }
    Rails.logger.info('[DevKeyRegistry] No PROMISE_KEY_REGISTRY_API_ROOT set — using local fake KMS')
  end
end
