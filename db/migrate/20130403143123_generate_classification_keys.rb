class GenerateClassificationKeys < ActiveRecord::Migration
  def self.up
    add_column :results, :classification_key, :string

    if Classification.count > 0
      seqs = Hash.new { |k,v| k[v] = 0 }
      Classification.includes(:illness).order('id ASC').all.each do |c|
        c.update_attribute :key, "#{c.age_group}.#{c.illness.sequence}.#{seqs[c.illness.id] += 1}"
      end

      klass = Class.new ActiveRecord::Base do
        set_table_name 'results'
        belongs_to :classification
        def self.name; 'Result'; end
      end

      klass.find_each(include: :classification) do |r|
        r.update_attribute :classification_key, r.classification.key
      end
    end

    remove_column :results, :classification_id
  end

  def self.down
    add_column :results, :classification_id, :int

    klass = Class.new ActiveRecord::Base do
      set_table_name 'results'
      belongs_to :classification, primary_key: :key, foreign_key: :classification_key
      def self.name; 'Result'; end
    end

    klass.find_each(include: :classification) do |r|
      r.update_attribute :classification_id, r.classification.id
    end

    remove_column :results, :classification_key
  end
end
