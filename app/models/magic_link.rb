# A one-click alternative to typing the e-mail verification code.
#
# The emailed link is "<id>.<secret>". The payload (e-mail, code and the
# login configuration, including redirect_uri) is stored encrypted with a
# key derived from the secret, and the secret only ever lives in the link
# itself — so neither the e-mail in transit nor our database exposes the
# login configuration on its own.
class MagicLink < ApplicationRecord
  TTL = 1.hour

  class << self
    # Returns the token to embed in the emailed link.
    def issue!(hashed_email:, payload:)
      id = SecureRandom.hex(16)
      secret = SecureRandom.urlsafe_base64(32)

      create!(
        id: id,
        hashed_email: hashed_email,
        ciphertext: encryptor(secret).encrypt_and_sign(payload)
      )

      "#{id}.#{secret}"
    end

    # Returns the decrypted payload, or nil when the token is malformed,
    # unknown, expired or tampered with. Read-only: the link is not
    # consumed, so mail scanners following it do no harm.
    def redeem(token)
      id, secret = token.to_s.split('.', 2)
      return nil if id.blank? || secret.blank?

      link = find_by(id: id)
      return nil if link.nil? || link.created_at < TTL.ago

      encryptor(secret).decrypt_and_verify(link.ciphertext)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def reset_for!(hashed_email)
      where(hashed_email: hashed_email).destroy_all
    end

    private

    def encryptor(secret)
      ActiveSupport::MessageEncryptor.new(
        OpenSSL::Digest::SHA256.digest(secret),
        serializer: JSON
      )
    end
  end
end
