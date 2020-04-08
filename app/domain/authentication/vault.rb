require 'digest/bubblebabble'

class Authentication::Vault
  include ActiveModel::Model

  attr_accessor :key

  def self.key_from(password, salt)
    mixed = RbNaCl::SecretBox.key_bytes.times.map do |index|
      if index % 2 == 0
        password[index % password.size]
      else
        salt[index % salt.size]
      end
    end.join

    sha = RbNaCl::Hash.sha256(mixed)
    blake = RbNaCl::Hash.blake2b(mixed)
    binary = sha + blake

    # Now get the hexdigest of
    binary.unpack('H*').first.encode('utf-8').first(32)
  end

  def encrypt(data)
    box.encrypt(data.to_json)
  end

  def decrypt(data)
    JSON.parse(box.decrypt(data))
  end

  private

  def box
    @box ||= RbNaCl::SimpleBox.from_secret_key(key.b)
  end

end
