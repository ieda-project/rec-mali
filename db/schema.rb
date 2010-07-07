# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100706114638) do

  create_table "children", :force => true do |t|
    t.integer  "village_id"
    t.string   "name"
    t.date     "born_on"
    t.boolean  "gender"
    t.datetime "last_visit_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "global_id"
    t.boolean  "imported"
    t.boolean  "temporary"
    t.boolean  "bcg_polio0"
    t.boolean  "penta1_polio1"
    t.boolean  "penta2_polio2"
    t.boolean  "penta3_polio3"
    t.boolean  "measles"
    t.string   "cache_name"
  end

  add_index "children", ["global_id"], :name => "index_children_on_global_id"

  create_table "classifications", :force => true do |t|
    t.string   "key"
    t.string   "name"
    t.text     "equation"
    t.text     "treatment"
    t.integer  "illness_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "in_imci"
    t.boolean  "in_gdt"
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
    t.string   "type"
    t.integer  "child_id"
    t.integer  "author_id"
    t.date     "done_on"
    t.integer  "height"
    t.integer  "mac"
    t.float    "weight"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "global_id"
    t.boolean  "imported"
  end

  add_index "diagnostics", ["author_id"], :name => "index_diagnostics_on_author_id"
  add_index "diagnostics", ["child_id"], :name => "index_diagnostics_on_child_id"
  add_index "diagnostics", ["type", "global_id"], :name => "index_diagnostics_on_type_and_global_id"
  add_index "diagnostics", ["type", "id"], :name => "index_diagnostics_on_type_and_id"

  create_table "illness_answers", :force => true do |t|
    t.integer  "illness_id"
    t.integer  "diagnostic_id"
    t.boolean  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "global_id"
    t.boolean  "imported"
  end

  add_index "illness_answers", ["diagnostic_id"], :name => "index_illness_answers_on_diagnostic_id"
  add_index "illness_answers", ["illness_id"], :name => "index_illness_answers_on_illness_id"

  create_table "illnesses", :force => true do |t|
    t.string   "key"
    t.string   "name"
    t.integer  "sequence"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "sign_answers", :force => true do |t|
    t.integer  "sign_id"
    t.integer  "diagnostic_id"
    t.string   "type"
    t.string   "list_value"
    t.boolean  "boolean_value"
    t.integer  "integer_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "global_id"
    t.boolean  "imported"
  end

  create_table "signs", :force => true do |t|
    t.string   "type"
    t.string   "key"
    t.string   "question"
    t.string   "values"
    t.integer  "illness_id"
    t.integer  "sequence"
    t.integer  "min_value"
    t.integer  "max_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", :force => true do |t|
    t.text     "locations"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "global_id"
    t.boolean  "imported"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "login"
    t.string   "crypted_password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "villages", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
