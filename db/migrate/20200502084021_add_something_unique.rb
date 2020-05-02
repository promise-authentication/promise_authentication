class AddSomethingUnique < ActiveRecord::Migration[6.0]
  def change
    create_table :authentication_something_uniques, id: :string do |t|
      t.string :color
      t.string :character
    end
  end
end
