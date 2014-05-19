class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :remember_token
      t.integer :amount_selling
      t.string :username

      t.timestamps
    end
  end
end
