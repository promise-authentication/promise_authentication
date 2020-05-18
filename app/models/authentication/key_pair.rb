class Authentication::KeyPair < ApplicationRecord
  # id is actually the public key base64 encoded
  # the private_key_cipher_base64 is the private key,
  # but encrypted with the off-site public key,
  # and the on-site private key which is discarded.
  # Such that it can only be decrypted with the off-site private key, 
  # and the on-site public key.
end
