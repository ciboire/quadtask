class CreateQuadtrees < ActiveRecord::Migration
  def self.up
    create_table :quadtrees do |t|
      t.string :title
      t.integer :position
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :quadtrees
  end
end
