class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :children, [:temporary, :zone_id]
    for model in %w(diagnostics results sign_answers users)
      add_index model, :zone_id
    end
  end

  def self.down
    remove_index :children, column: [:temporary, :zone_id]
    for model in %w(diagnostics results sign_answers users)
      remove_index model, column: :zone_id
    end
  end
end
