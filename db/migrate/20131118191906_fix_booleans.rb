class FixBooleans < ActiveRecord::Migration
  def self.up
    fixes = {
      'children' =>
        %w(gender bcg_polio0 penta1_polio1 penta2_polio2 penta3_polio3 measles temporary),
      'classifications' =>
        %w(in_imci in_gdt),
      'illness_answers' =>
        %w(value),
      'indices' =>
        %w(for_boys above_2yrs),
      'prescriptions' =>
        %w(mandatory),
      'serial_numbers' =>
        %w(exported),
      'sign_answers' =>
        %w(boolean_value),
      'signs' =>
        %w(negative),
      'treatment_helps' =>
        %w(image),
      'zones' =>
        %w(here accessible point village restoring custom) }

    fixes.each do |table,cols|
      cols.each do |col|
        execute "UPDATE #{table} SET #{col}='t' WHERE #{col}=1"
        execute "UPDATE #{table} SET #{col}='f' WHERE #{col}=0"
      end
    end
  end

  def self.down
  end
end
