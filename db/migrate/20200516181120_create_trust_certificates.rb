class CreateTrustCertificates < ActiveRecord::Migration[6.0]
  def change
    create_table :trust_certificates do |t|
      t.text :public_key
      t.text :private_key
      t.datetime :expires_at

      t.timestamps

      t.index :expires_at
    end
    # Make sure we create one now
    Trust::Certificate.rotate!
  end
end
