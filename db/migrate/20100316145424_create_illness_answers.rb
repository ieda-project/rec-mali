class CreateIllnessAnswers < ActiveRecord::Migration
  def self.up
    create_table :illness_answers do |t|
      t.references :illness, :diagnostic
      t.boolean :value
      t.timestamps

      t.string :global_id
      t.boolean :imported
    end
    add_index :illness_answers, :illness_id
    add_index :illness_answers, :diagnostic_id
  end

  def self.down
    drop_table :illness_answers
  end
end
