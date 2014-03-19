class MoveDistanceToDiag < ActiveRecord::Migration
  def self.up
    add_column :diagnostics, :distance, :integer #enum
    Diagnostic.reset_column_information

    Child.where('distance IS NOT NULL').includes(:last_visit).find_each do |ch|
      ch.last_visit.update_attribute :distance, ch.distance if ch.last_visit
    end
    remove_column :children, :distance
  end

  def self.down
    remove_column :diagnostics, :distance
    add_column :children, :distance, :integer
  end
end
