class CreateMagicLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :magic_links, id: :string do |t|
      t.string :hashed_email, null: false, index: true
      t.text :ciphertext, null: false

      t.timestamps
    end
  end
end
