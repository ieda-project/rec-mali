class CreatePrescriptions < ActiveRecord::Migration
  def self.up
    create_table :prescriptions do |t|
      t.timestamps
      t.belongs_to :treatment, :medicine
      t.text :duration, :takes, :instructions
    end
  end

  def self.down
    drop_table :prescriptions
  end
end
