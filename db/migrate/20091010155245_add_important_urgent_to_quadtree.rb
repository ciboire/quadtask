class AddImportantUrgentToQuadtree < ActiveRecord::Migration
  def self.up
    add_column :quadtrees, :important_urgent, :string, :default => "IMPORTANT / URGENT"
    add_column :quadtrees, :important_not_urgent, :string, :default => "IMPORTANT / not urgent"
    add_column :quadtrees, :not_important_urgent, :string, :default => "not important / URGENT"
    add_column :quadtrees, :not_important_not_urgent, :string, :default => "not important / not urgent"
  end

  def self.down
    remove_column :quadtrees, :important_urgent
    remove_column :quadtrees, :important_not_urgent
    remove_column :quadtrees, :not_important_urgent
    remove_column :quadtrees, :not_important_not_urgent
  end
end
