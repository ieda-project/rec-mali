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

ActiveRecord::Schema.define(:version => 20100316145742) do

  create_table "child_photos", :force => true do |t|
    t.string   "global_id"
    t.integer  "child_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "child_photos", ["child_id"], :name => "index_child_photos_on_child_id"
  add_index "child_photos", ["global_id"], :name => "index_child_photos_on_global_id"

  create_table "children", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.date     "born_on"
    t.string   "global_id"
    t.boolean  "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "children", ["global_id"], :name => "index_children_on_global_id"

  create_table "classifications", :force => true do |t|
    t.string   "key"
    t.text     "equation"
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

  create_table "classifications_treatments", :id => false, :force => true do |t|
    t.integer "classification_id"
    t.integer "treatment_id"
  end

  create_table "diagnostics", :force => true do |t|
    t.string   "type"
    t.string   "global_id"
    t.integer  "child_id"
    t.integer  "author_id"
    t.date     "done_on"
    t.integer  "height"
    t.integer  "mac"
    t.float    "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  add_index "illness_answers", ["diagnostic_id"], :name => "index_illness_answers_on_diagnostic_id"
  add_index "illness_answers", ["illness_id"], :name => "index_illness_answers_on_illness_id"

  create_table "illnesses", :force => true do |t|
    t.string   "key"
    t.integer  "sequence"
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
  end

  create_table "signs", :force => true do |t|
    t.string   "type"
    t.string   "key"
    t.string   "values"
    t.integer  "illness_id"
    t.integer  "sequence"
    t.integer  "min_value"
    t.integer  "max_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", :force => true do |t|
    t.string   "global_id"
    t.text     "locations"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "treatments", :force => true do |t|
    t.string   "key"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "treatments", ["key"], :name => "index_treatments_on_key"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "login"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
