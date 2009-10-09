class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.string :tx_token
      t.decimal :amount
      t.integer :user_id
      t.string :user_email
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
