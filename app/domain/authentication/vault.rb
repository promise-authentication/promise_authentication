require 'digest/bubblebabble'

class Authentication::Vault
  include ActiveModel::Model

  attr_accessor :key

  def self.personal_data(user_id, vault_key)
    personal_data!(user_id, vault_key)
  rescue RbNaCl::CryptoError, ActiveRecord::RecordNotFound
    nil
  end

  def self.personal_data!(user_id, vault_key)
    encrypted = Authentication::VaultContent
                .find(user_id)
                .encrypted_personal_data

    decrypted = Authentication::Vault
                .new(key: vault_key)
                .decrypt encrypted

    Authentication::PersonalData.new(decrypted)
  end

  def self.generate_salt
    RbNaCl::Random.random_bytes(RbNaCl::PasswordHash::SCrypt::SALTBYTES)
  end

  def self.key_from(password, salt)
    opslimit = 2**20
    memlimit = 2**24

    # Size of digest to compute in bytes (default 64)
    digest_size = 32

    RbNaCl::PasswordHash.scrypt(
      password.b,
      salt,
      opslimit,
      memlimit,
      digest_size
    )
  end

  def encrypt(data)
    box.encrypt(data.to_json)
  end

  def decrypt(data)
    JSON.parse(box.decrypt(data))
  end

  private

  def box
    @box ||= RbNaCl::SimpleBox.from_secret_key(key)
  end
end
