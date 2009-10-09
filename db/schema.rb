# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091009012722) do

  create_table "faqs", :force => true do |t|
    t.string   "question"
    t.string   "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.string   "tx_token"
    t.decimal  "amount"
    t.integer  "user_id"
    t.string   "user_email"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quadtrees", :force => true do |t|
    t.string   "title"
    t.integer  "position"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.string   "title"
    t.boolean  "is_crossed_out", :default => false
    t.boolean  "is_important",   :default => false
    t.boolean  "is_urgent",      :default => false
    t.integer  "quadtree_id",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",       :default => 0
  end

  create_table "users", :force => true do |t|
    t.string   "tx_token"
    t.boolean  "tx_accepted"
    t.string   "membership_level",                        :default => "free"
    t.datetime "membership_modified_at"
    t.string   "email"
    t.string   "remember_token"
    t.string   "crypted_password",          :limit => 40
    t.string   "password_reset_code",       :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "activation_code",           :limit => 40
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.datetime "deleted_at"
    t.string   "state",                                   :default => "passive"
  end

end
