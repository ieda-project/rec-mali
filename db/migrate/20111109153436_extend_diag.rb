class ExtendDiag < ActiveRecord::Migration
  class Diagnostic < ActiveRecord::Base
    include Csps::Exportable
    globally_belongs_to :child
  end

  def self.up
    add_column :diagnostics, :temperature, :float
    add_column :diagnostics, :born_on, :date
    Diagnostic.includes(:child).find_each do |diag|
      diag.update_attribute :born_on, diag.child.born_on
    end
  end

  def self.down
    remove_column :diagnostics, :born_on
    remove_column :diagnostics, :temperature
  end
end
