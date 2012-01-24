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

    sign = Sign.where(
      key: 'fievre_presence',
      age_group: Csps::Age['child']).first.id
    subselect = SignAnswer.
      select(:diagnostic_global_id).
      where(sign_id: sign, boolean_value: true)

    Sign.connection.execute(
      "UPDATE diagnostics SET temperature=38
       WHERE global_id IN (#{subselect.to_sql})")
    Sign.connection.execute(
      'UPDATE diagnostics SET temperature=37.5
       WHERE temperature IS NULL')
  end

  def self.down
    remove_column :diagnostics, :born_on
    remove_column :diagnostics, :temperature
  end
end
