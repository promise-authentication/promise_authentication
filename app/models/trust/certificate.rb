class Trust::Certificate < ApplicationRecord
  scope :unexpired, -> { where('expires_at > ?', Time.now).order('expires_at DESC') }

  def self.current
    last
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
    pair = OpenSSL::PKey::EC.generate 'secp521r1'

    create(
      expires_at: 2.days.from_now,
      private_key: pair.private_to_pem,
      public_key: pair.public_to_pem
    )
  end
end
