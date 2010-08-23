class CreateSignAnswers < ActiveRecord::Migration
  def self.up
    create_table :sign_answers do |t|
      t.references :sign
      t.string :diagnostic_global_id
      t.string :type, :list_value
      t.boolean :boolean_value
      t.integer :integer_value
      t.timestamps

      t.string :global_id
      t.boolean :imported
    end
  end

  def self.down
    drop_table :sign_answers
  end
end
