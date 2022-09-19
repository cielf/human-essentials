class CreateCounties < ActiveRecord::Migration[7.0]
  def change
    create_table :counties do |t|
      t.string :name
      t.string :state_or_territory

      t.timestamps
    end
  end
end
