class AddIllnessAgeGroup < ActiveRecord::Migration
  def self.up
    add_column :illnesses, :age_group, :int

    if Illness.count > 0
      Illness.reset_column_information

      Illness.all.each do |i|
        i.update_attribute :age_group, i.classifications.first.age_group
      end
    end
  end

  def self.down
    remove_column :illnesses, :age_group
  end
end
