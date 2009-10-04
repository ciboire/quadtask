class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.string :membership_level, :default => 'free'
      t.datetime :membership_modified_at
      t.string :email, :remember_token
      t.string :crypted_password,          :limit => 40
      t.string :password_reset_code,       :limit => 40
      t.string :salt,                      :limit => 40      
      t.string :activation_code,           :limit => 40
      t.datetime :remember_token_expires_at, :activated_at, :deleted_at
      t.string :state, :null => :no, :default => 'passive'
    end
  end

  def self.down
    drop_table "users"
  end
end
