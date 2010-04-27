class CreateSignAnswers < ActiveRecord::Migration
  def self.up
    create_table :sign_answers do |t|
      t.string :global_id
      t.references :sign, :diagnostic
      t.string :type, :list_value
      t.boolean :boolean_value
      t.integer :integer_value
      t.timestamps
    end
  end

  def self.down
    drop_table :sign_answers
  end
end
