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

ActiveRecord::Schema.define(:version => 20140325171810) do

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
    t.string   "cache_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "temporary"
    t.integer  "zone_id"
    t.integer  "uqid"
    t.string   "village_name"
    t.string   "mother"
    t.integer  "v_bcg"
    t.integer  "v_polio0"
    t.integer  "v_polio1"
    t.integer  "v_polio2"
    t.integer  "v_polio3"
    t.integer  "v_penta1"
    t.integer  "v_penta2"
    t.integer  "v_penta3"
    t.integer  "v_pneumo1"
    t.integer  "v_pneumo2"
    t.integer  "v_pneumo3"
    t.integer  "v_rota1"
    t.integer  "v_rota2"
    t.integer  "v_rota3"
    t.integer  "v_measles"
    t.integer  "v_yellow"
  end

  add_index "children", ["temporary", "zone_id"], :name => "index_children_on_temporary_and_zone_id"
  add_index "children", ["uqid"], :name => "index_children_on_uqid", :unique => true

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
    t.boolean  "removed"
  end

  add_index "classifications", ["age_group", "removed"], :name => "index_classifications_on_age_group_and_removed"
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
    t.datetime "done_on"
    t.integer  "mac"
    t.float    "height"
    t.float    "weight"
    t.text     "comments"
    t.string   "failed_classifications"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.integer  "saved_age_group"
    t.float    "temperature"
    t.date     "born_on"
    t.string   "state"
    t.integer  "kind"
    t.integer  "month"
    t.integer  "uqid"
    t.integer  "child_uqid"
    t.integer  "author_uqid"
    t.string   "ordonnance"
    t.text     "other_problems"
  end

  add_index "diagnostics", ["author_uqid"], :name => "index_diagnostics_on_author_uqid"
  add_index "diagnostics", ["child_uqid"], :name => "index_diagnostics_on_child_uqid"
  add_index "diagnostics", ["kind"], :name => "index_diagnostics_on_kind"
  add_index "diagnostics", ["month"], :name => "index_diagnostics_on_month"
  add_index "diagnostics", ["saved_age_group", "state"], :name => "index_diagnostics_on_saved_age_group_and_state"
  add_index "diagnostics", ["type", "id"], :name => "index_diagnostics_on_type_and_id"
  add_index "diagnostics", ["type", "uqid"], :name => "index_diagnostics_on_type_and_uqid"
  add_index "diagnostics", ["uqid"], :name => "index_diagnostics_on_uqid", :unique => true
  add_index "diagnostics", ["zone_id"], :name => "index_diagnostics_on_zone_id"

  create_table "events", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "kind"
  end

  add_index "events", ["kind"], :name => "index_events_on_kind"

  create_table "illness_answers", :force => true do |t|
    t.boolean  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.integer  "uqid"
    t.integer  "diagnostic_uqid"
  end

  add_index "illness_answers", ["diagnostic_uqid"], :name => "index_illness_answers_on_diagnostic_uqid"
  add_index "illness_answers", ["uqid"], :name => "index_illness_answers_on_uqid", :unique => true

  create_table "illnesses", :force => true do |t|
    t.string   "key"
    t.string   "name"
    t.integer  "sequence"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "age_group"
  end

  create_table "import_versions", :force => true do |t|
    t.string   "key"
    t.string   "version"
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
    t.float    "sd4neg"
    t.float    "sd4"
    t.float    "sd3neg"
    t.float    "sd2neg"
    t.float    "sd1neg"
    t.float    "sd1"
    t.float    "sd2"
    t.float    "sd3"
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
    t.boolean  "mandatory"
  end

  create_table "queries", :force => true do |t|
    t.string   "title"
    t.string   "klass"
    t.integer  "case_status"
    t.text     "conditions"
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "group_title"
    t.string   "distinct"
  end

  create_table "results", :force => true do |t|
    t.integer  "classification_id"
    t.integer  "zone_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "treatment_id"
    t.integer  "uqid"
    t.integer  "diagnostic_uqid"
  end

  add_index "results", ["classification_id"], :name => "index_results_on_classification_id"
  add_index "results", ["diagnostic_uqid"], :name => "index_results_on_diagnostic_uqid"
  add_index "results", ["uqid"], :name => "index_results_on_uqid", :unique => true
  add_index "results", ["zone_id"], :name => "index_results_on_zone_id"

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
    t.string   "type"
    t.string   "list_value"
    t.boolean  "boolean_value"
    t.integer  "integer_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.integer  "uqid"
    t.integer  "diagnostic_uqid"
  end

  add_index "sign_answers", ["uqid"], :name => "index_sign_answers_on_uqid", :unique => true
  add_index "sign_answers", ["zone_id"], :name => "index_sign_answers_on_zone_id"

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
    t.boolean  "retired"
  end

  add_index "signs", ["retired"], :name => "index_signs_on_retired"

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
    t.string   "key"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "crypted_password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.integer  "uqid"
    t.datetime "password_expired_at"
    t.datetime "admin_at"
  end

  add_index "users", ["uqid"], :name => "index_users_on_uqid", :unique => true
  add_index "users", ["zone_id"], :name => "index_users_on_zone_id"

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
    t.boolean  "custom"
    t.datetime "exported_at"
  end

  add_index "zones", ["custom"], :name => "index_zones_on_custom"

end
