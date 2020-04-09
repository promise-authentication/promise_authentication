require 'digest/bubblebabble'

class Authentication::Vault
  include ActiveModel::Model

  attr_accessor :key

  def self.personal_data(user_id, vault_key)
    encrypted = Authentication::VaultContent.
      find(user_id).
      encrypted_personal_data

    decrypted = Authentication::Vault.
      new(key: vault_key).
      decrypt encrypted

    Authentication::PersonalData.new(decrypted)
  end

  def self.key_from(password, salt)
    mixed = RbNaCl::SecretBox.key_bytes.times.map do |index|
      if index % 2 == 0
        password[index % password.size]
      else
        salt[index % salt.size]
      end
    end.join

    Digest::SHA256.bubblebabble(mixed).first(32).encode('utf-8')
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
