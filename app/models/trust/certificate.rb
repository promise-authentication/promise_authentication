class Trust::Certificate < ApplicationRecord

  scope :unexpired, -> { where('expires_at > ?', Time.now).order('expires_at DESC') }

  def self.current
    self.last
  end

  def self.rotate!
    generate_key_pair!
  end

  def private_key
    OpenSSL::PKey::EC.new(self[:private_key])
  end

  def public_key
    OpenSSL::PKey::EC.new(self[:public_key])
  end

  def self.generate_key_pair!
    ecdsa_key = OpenSSL::PKey::EC.new 'secp521r1'
    ecdsa_key.generate_key
    ecdsa_public = OpenSSL::PKey::EC.new ecdsa_key
    ecdsa_public.private_key = nil

    return create(
      expires_at: 2.days.from_now,
      private_key: ecdsa_key.to_pem,
      public_key: ecdsa_public.to_pem
    )
  end
end
