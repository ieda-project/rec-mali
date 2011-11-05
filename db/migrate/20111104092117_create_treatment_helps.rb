class CreateTreatmentHelps < ActiveRecord::Migration
  def self.up
    create_table :treatment_helps do |t|
      t.timestamps
      t.string :key, :title
      t.text :content
    end
  end

  def self.down
    drop_table :treatment_helps
  end
end
