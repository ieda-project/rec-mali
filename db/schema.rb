# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120723200206) do

  create_table "children", :force => true do |t|
    t.integer  "village_id"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "born_on"
    t.boolean  "gender"
    t.datetime "last_visit_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.boolean  "bcg_polio0"
    t.boolean  "penta1_polio1"
    t.boolean  "penta2_polio2"
    t.boolean  "penta3_polio3"
    t.boolean  "measles"
    t.string   "cache_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "temporary"
    t.integer  "zone_id"
    t.string   "global_id"
  end

  add_index "children", ["global_id"], :name => "index_children_on_global_id"

  create_table "classifications", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "illness_id"
    t.string   "key"
    t.string   "name"
    t.text     "equation"
    t.boolean  "in_imci"
    t.boolean  "in_gdt"
    t.integer  "level"
    t.integer  "age_group"
  end

  add_index "classifications", ["illness_id"], :name => "index_classifications_on_illness_id"

  create_table "classifications_diagnostics", :id => false, :force => true do |t|
    t.integer "classification_id"
    t.integer "diagnostic_id"
  end

  create_table "classifications_signs", :id => false, :force => true do |t|
    t.integer "classification_id"
    t.integer "sign_id"
  end

  create_table "diagnostics", :force => true do |t|
    t.string   "child_global_id"
    t.string   "author_global_id"
    t.string   "type"
    t.datetime "done_on"
    t.integer  "mac"
    t.float    "height"
    t.float    "weight"
    t.text     "comments"
    t.string   "failed_classifications"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.string   "global_id"
    t.integer  "saved_age_group"
    t.float    "temperature"
    t.date     "born_on"
    t.string   "state"
  end

  add_index "diagnostics", ["author_global_id"], :name => "index_diagnostics_on_author_global_id"
  add_index "diagnostics", ["child_global_id"], :name => "index_diagnostics_on_child_global_id"
  add_index "diagnostics", ["type", "global_id"], :name => "index_diagnostics_on_type_and_global_id"
  add_index "diagnostics", ["type", "id"], :name => "index_diagnostics_on_type_and_id"

  create_table "illness_answers", :force => true do |t|
    t.string   "illness_global_id"
    t.string   "diagnostic_global_id"
    t.boolean  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.string   "global_id"
  end

  add_index "illness_answers", ["diagnostic_global_id"], :name => "index_illness_answers_on_diagnostic_global_id"
  add_index "illness_answers", ["illness_global_id"], :name => "index_illness_answers_on_illness_global_id"

  create_table "illnesses", :force => true do |t|
    t.string   "key"
    t.string   "name"
    t.integer  "sequence"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "indices", :force => true do |t|
    t.float    "x"
    t.float    "y"
    t.integer  "name"
    t.boolean  "for_boys"
    t.boolean  "above_2yrs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "medicines", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "key"
    t.string   "unit"
    t.text     "formula"
    t.text     "code"
  end

  create_table "prescriptions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "treatment_id"
    t.integer  "medicine_id"
    t.text     "duration"
    t.text     "takes"
    t.text     "instructions"
  end

  create_table "queries", :force => true do |t|
    t.string   "title"
    t.string   "klass"
    t.integer  "case_status"
    t.text     "conditions"
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", :force => true do |t|
    t.integer  "classification_id"
    t.string   "diagnostic_global_id"
    t.integer  "zone_id"
    t.string   "global_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "treatment_id"
  end

  add_index "results", ["classification_id"], :name => "index_results_on_classification_id"
  add_index "results", ["diagnostic_global_id"], :name => "index_results_on_diagnostic_global_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.text     "permissions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "serial_numbers", :force => true do |t|
    t.integer  "zone_id"
    t.string   "model"
    t.integer  "value",      :default => 0,     :null => false
    t.boolean  "exported",   :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sign_answers", :force => true do |t|
    t.integer  "sign_id"
    t.string   "diagnostic_global_id"
    t.string   "type"
    t.string   "list_value"
    t.boolean  "boolean_value"
    t.integer  "integer_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.string   "global_id"
  end

  create_table "signs", :force => true do |t|
    t.integer  "illness_id"
    t.string   "type"
    t.string   "key"
    t.string   "question"
    t.string   "values"
    t.text     "dep"
    t.integer  "sequence"
    t.integer  "min_value"
    t.integer  "max_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "age_group"
    t.boolean  "negative"
    t.text     "auto"
  end

  create_table "sites", :force => true do |t|
    t.text     "locations"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.string   "global_id"
  end

  create_table "treatment_helps", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.string   "title"
    t.text     "content"
    t.boolean  "image"
  end

  create_table "treatments", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classification_id"
    t.string   "name"
    t.text     "description"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "crypted_password"
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.string   "global_id"
  end

  create_table "zones", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "name"
    t.boolean  "here"
    t.boolean  "accessible"
    t.boolean  "point"
    t.datetime "last_import_at"
    t.datetime "last_export_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "village"
    t.boolean  "restoring"
  end

end
