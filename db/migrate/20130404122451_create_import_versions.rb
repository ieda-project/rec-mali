class CreateImportVersions < ActiveRecord::Migration
  def self.up
    create_table :import_versions do |t|
      t.string :key, :version
      t.timestamps
    end
  end

  def self.down
    drop_table :import_versions
  end
end
