class CreateIllnessAnswers < ActiveRecord::Migration
  def self.up
    create_table :illness_answers do |t|
      t.string :illness_global_id, :diagnostic_global_id
      t.boolean :value
      t.timestamps

      t.references :zone
      t.string :global_id
    end
    add_index :illness_answers, :illness_global_id
    add_index :illness_answers, :diagnostic_global_id
  end

  def self.down
    drop_table :illness_answers
  end
end
