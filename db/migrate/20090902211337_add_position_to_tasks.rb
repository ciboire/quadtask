class AddPositionToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :position, :int, :default => 0
  end

  def self.down
    remove_column :tasks, :position
  end
end
