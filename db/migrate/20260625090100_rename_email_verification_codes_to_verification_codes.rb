class RenameEmailVerificationCodesToVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    rename_table :email_verification_codes, :verification_codes
  end
end
