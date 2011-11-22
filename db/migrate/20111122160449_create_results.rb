class CreateResults < ActiveRecord::Migration
  # We need these classes, because in 'down' the Result model will
  # probably not exist, and in 'up' Diagnostic already includes
  # the new code:

  class Result < ActiveRecord::Base
    set_table_name 'results'
    belongs_to :classification, primary_key: :global_id, foreign_key: :classification_global_id
    belongs_to :diagnostic, primary_key: :global_id, foreign_key: :diagnostic_global_id
  end

  class Diagnostic < ActiveRecord::Base
    set_table_name 'diagnostics'
    has_and_belongs_to_many :classifications, join_table: 'classifications_diagnostics'
  end

  # --------------

  def self.up
    create_table :results do |t|
      t.belongs_to :classification
      t.string :diagnostic_global_id
      t.references :zone
      t.string :global_id
      t.timestamps
    end
    add_index :results, :diagnostic_global_id
    add_index :results, :classification_id

    Diagnostic.includes(:classifications).find_each do |diag|
      diag.classifications.each do |clx|
        # Keep the double colon, here we need the Result class from the app!
        ::Result.create!(diagnostic_global_id: diag.global_id, classification: clx)
      end
    end
  end

  def self.down
    create_table :classifications_diagnostics, :id => false do |t|
      t.references :classification, :diagnostic
    end

    Result.includes(:classification, :diagnostic).find_each do |res|
      Result.connection.execute("INSERT
        INTO classifications_diagnostics (diagnostic_id,classification_id)
        VALUES (#{res.diagnostic.id}, #{res.classification.id})")
    end

    drop_table :results
  end
end
