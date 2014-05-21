class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :description
      t.integer :amount
      t.string :state

      t.timestamps
    end
  end
end
