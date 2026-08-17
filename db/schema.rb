# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_17_161500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "assignment_status", ["active", "completed", "paused", "abandoned"]
  create_enum "distance_unit", ["m", "km", "mi"]
  create_enum "equipment_kind", ["dumbbell", "barbell", "kettlebell", "band", "machine", "bodyweight", "cardio", "accessory", "other"]
  create_enum "execution_mode", ["straight_sets", "circuit", "interval", "paired"]
  create_enum "import_source_type", ["paste", "pdf"]
  create_enum "import_status", ["pending", "parsed", "review", "committed", "failed"]
  create_enum "load_kind", ["none", "bodyweight", "external", "band", "machine"]
  create_enum "load_unit", ["lb", "kg"]
  create_enum "measure_kind", ["reps", "time", "distance", "calories"]
  create_enum "practitioner_specialty", ["trainer", "nutritionist"]
  create_enum "program_version_status", ["draft", "published", "archived"]
  create_enum "relationship_status", ["invited", "active", "paused", "ended"]
  create_enum "relationship_type", ["trainer", "nutritionist"]
  create_enum "session_status", ["pending", "in_progress", "completed", "skipped"]
  create_enum "unit_system", ["metric", "imperial"]
  create_enum "user_role", ["practitioner", "client", "admin"]

  create_table "block_exercise_alternatives", force: :cascade do |t|
    t.bigint "block_exercise_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "position", default: 1, null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_exercise_id", "exercise_id"], name: "idx_block_exercise_alts_unique", unique: true
    t.index ["block_exercise_id"], name: "index_block_exercise_alternatives_on_block_exercise_id"
    t.index ["exercise_id"], name: "index_block_exercise_alternatives_on_exercise_id"
  end

  create_table "block_exercises", force: :cascade do |t|
    t.bigint "program_block_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "position", null: false
    t.boolean "per_side", default: false, null: false
    t.text "technique_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_block_exercises_on_exercise_id"
    t.index ["program_block_id", "position"], name: "index_block_exercises_on_program_block_id_and_position"
    t.index ["program_block_id"], name: "index_block_exercises_on_program_block_id"
  end

  create_table "check_ins", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "program_assignment_id"
    t.date "week_of", null: false
    t.decimal "bodyweight_kg", precision: 5, scale: 2
    t.integer "feeling"
    t.decimal "sleep_hours_avg", precision: 3, scale: 1
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "week_of"], name: "index_check_ins_on_client_id_and_week_of", unique: true
    t.index ["client_id"], name: "index_check_ins_on_client_id"
    t.index ["program_assignment_id"], name: "index_check_ins_on_program_assignment_id"
    t.check_constraint "feeling IS NULL OR feeling >= 1 AND feeling <= 10", name: "chk_feeling_range"
  end

  create_table "client_equipment", force: :cascade do |t|
    t.bigint "client_profile_id", null: false
    t.bigint "equipment_item_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_profile_id", "equipment_item_id"], name: "idx_client_equipment_unique", unique: true
    t.index ["client_profile_id"], name: "index_client_equipment_on_client_profile_id"
    t.index ["equipment_item_id"], name: "index_client_equipment_on_equipment_item_id"
  end

  create_table "client_injuries", force: :cascade do |t|
    t.bigint "client_profile_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.date "reported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_profile_id"], name: "index_client_injuries_on_client_profile_id"
  end

  create_table "client_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "birth_year"
    t.decimal "height_cm", precision: 5, scale: 1
    t.string "sex"
    t.string "goal"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_client_profiles_on_user_id", unique: true
  end

  create_table "equipment_items", force: :cascade do |t|
    t.string "name_es", null: false
    t.string "name_en"
    t.enum "kind", null: false, enum_type: "equipment_kind"
    t.string "resistance_label"
    t.decimal "default_load_value", precision: 7, scale: 2
    t.enum "default_load_unit", enum_type: "load_unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_es"], name: "index_equipment_items_on_name_es", unique: true
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name_es", null: false
    t.string "name_en"
    t.string "slug", null: false
    t.string "search_name", default: "", null: false
    t.string "muscle_group"
    t.string "secondary_muscles", default: [], array: true
    t.string "movement_pattern"
    t.enum "default_measure_kind", default: "reps", null: false, enum_type: "measure_kind"
    t.bigint "default_equipment_item_id"
    t.text "technique_notes"
    t.string "reference_url"
    t.bigint "practitioner_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default_equipment_item_id"], name: "index_exercises_on_default_equipment_item_id"
    t.index ["muscle_group"], name: "index_exercises_on_muscle_group"
    t.index ["practitioner_id"], name: "index_exercises_on_practitioner_id"
    t.index ["search_name"], name: "idx_exercises_search_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["search_name"], name: "index_exercises_on_search_name"
    t.index ["slug"], name: "index_exercises_on_slug", unique: true
  end

  create_table "plan_imports", force: :cascade do |t|
    t.bigint "practitioner_id", null: false
    t.enum "source_type", default: "paste", null: false, enum_type: "import_source_type"
    t.text "source_text"
    t.jsonb "parsed_payload", default: {}, null: false
    t.jsonb "confidence_flags", default: {}, null: false
    t.enum "status", default: "pending", null: false, enum_type: "import_status"
    t.text "error_message"
    t.bigint "program_version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practitioner_id", "status"], name: "index_plan_imports_on_practitioner_id_and_status"
    t.index ["practitioner_id"], name: "index_plan_imports_on_practitioner_id"
    t.index ["program_version_id"], name: "index_plan_imports_on_program_version_id"
  end

  create_table "practitioner_clients", force: :cascade do |t|
    t.bigint "practitioner_id", null: false
    t.bigint "client_id", null: false
    t.enum "relationship_type", default: "trainer", null: false, enum_type: "relationship_type"
    t.enum "status", default: "invited", null: false, enum_type: "relationship_status"
    t.datetime "invited_at"
    t.datetime "accepted_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_practitioner_clients_on_client_id"
    t.index ["practitioner_id", "client_id", "relationship_type"], name: "idx_practitioner_clients_unique", unique: true
    t.index ["practitioner_id"], name: "index_practitioner_clients_on_practitioner_id"
  end

  create_table "practitioner_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.enum "specialty", default: "trainer", null: false, enum_type: "practitioner_specialty"
    t.text "bio"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_practitioner_profiles_on_user_id", unique: true
  end

  create_table "prescribed_sets", force: :cascade do |t|
    t.bigint "block_exercise_id", null: false
    t.integer "set_number", null: false
    t.integer "segment_number", default: 1, null: false
    t.enum "measure_kind", default: "reps", null: false, enum_type: "measure_kind"
    t.integer "reps_min"
    t.integer "reps_max"
    t.integer "work_seconds"
    t.decimal "distance_value", precision: 9, scale: 2
    t.enum "distance_unit", enum_type: "distance_unit"
    t.integer "calories"
    t.enum "load_kind", default: "none", null: false, enum_type: "load_kind"
    t.decimal "load_value", precision: 7, scale: 2
    t.decimal "load_value_max", precision: 7, scale: 2
    t.enum "load_unit", enum_type: "load_unit"
    t.bigint "equipment_item_id"
    t.string "load_note"
    t.decimal "target_rpe", precision: 3, scale: 1
    t.integer "rest_seconds"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_exercise_id", "set_number", "segment_number"], name: "idx_prescribed_sets_unique", unique: true
    t.index ["block_exercise_id"], name: "index_prescribed_sets_on_block_exercise_id"
    t.index ["equipment_item_id"], name: "index_prescribed_sets_on_equipment_item_id"
    t.check_constraint "measure_kind = 'reps'::measure_kind AND reps_min IS NOT NULL OR measure_kind = 'time'::measure_kind AND work_seconds IS NOT NULL OR measure_kind = 'distance'::measure_kind AND distance_value IS NOT NULL OR measure_kind = 'calories'::measure_kind AND calories IS NOT NULL", name: "chk_measure_kind_columns"
    t.check_constraint "reps_max IS NULL OR reps_min IS NULL OR reps_max >= reps_min", name: "chk_rep_range_ordered"
    t.check_constraint "target_rpe IS NULL OR target_rpe >= 1::numeric AND target_rpe <= 10::numeric", name: "chk_rpe_range"
  end

  create_table "program_assignments", force: :cascade do |t|
    t.bigint "program_version_id", null: false
    t.bigint "client_id", null: false
    t.bigint "practitioner_id", null: false
    t.date "starts_on", null: false
    t.date "ends_on"
    t.enum "status", default: "active", null: false, enum_type: "assignment_status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "status"], name: "index_program_assignments_on_client_id_and_status"
    t.index ["client_id"], name: "index_program_assignments_on_client_id"
    t.index ["practitioner_id"], name: "index_program_assignments_on_practitioner_id"
    t.index ["program_version_id"], name: "index_program_assignments_on_program_version_id"
  end

  create_table "program_blocks", force: :cascade do |t|
    t.bigint "program_day_id", null: false
    t.bigint "parent_block_id"
    t.integer "position", null: false
    t.string "name"
    t.enum "execution_mode", default: "straight_sets", null: false, enum_type: "execution_mode"
    t.integer "round_count"
    t.integer "work_seconds"
    t.integer "rest_seconds"
    t.integer "rest_between_rounds_seconds"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_block_id"], name: "index_program_blocks_on_parent_block_id"
    t.index ["program_day_id", "position"], name: "index_program_blocks_on_program_day_id_and_position"
    t.index ["program_day_id"], name: "index_program_blocks_on_program_day_id"
  end

  create_table "program_days", force: :cascade do |t|
    t.bigint "program_week_id", null: false
    t.integer "position", null: false
    t.string "name"
    t.string "focus"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_week_id", "position"], name: "index_program_days_on_program_week_id_and_position", unique: true
    t.index ["program_week_id"], name: "index_program_days_on_program_week_id"
  end

  create_table "program_versions", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.integer "version_number", default: 1, null: false
    t.enum "status", default: "draft", null: false, enum_type: "program_version_status"
    t.integer "duration_weeks"
    t.datetime "published_at"
    t.bigint "source_import_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id", "version_number"], name: "index_program_versions_on_program_id_and_version_number", unique: true
    t.index ["program_id"], name: "index_program_versions_on_program_id"
    t.index ["source_import_id"], name: "index_program_versions_on_source_import_id"
  end

  create_table "program_weeks", force: :cascade do |t|
    t.bigint "program_version_id", null: false
    t.integer "position", null: false
    t.string "name"
    t.string "focus"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_version_id", "position"], name: "index_program_weeks_on_program_version_id_and_position", unique: true
    t.index ["program_version_id"], name: "index_program_weeks_on_program_version_id"
  end

  create_table "programs", force: :cascade do |t|
    t.bigint "practitioner_id", null: false
    t.string "name", null: false
    t.string "goal"
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practitioner_id"], name: "index_programs_on_practitioner_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "program_assignment_id", null: false
    t.bigint "program_day_id", null: false
    t.date "scheduled_for"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.enum "status", default: "pending", null: false, enum_type: "session_status"
    t.decimal "overall_rpe", precision: 3, scale: 1
    t.integer "duration_seconds"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_assignment_id", "scheduled_for"], name: "index_sessions_on_program_assignment_id_and_scheduled_for"
    t.index ["program_assignment_id", "status"], name: "index_sessions_on_program_assignment_id_and_status"
    t.index ["program_assignment_id"], name: "index_sessions_on_program_assignment_id"
    t.index ["program_day_id"], name: "index_sessions_on_program_day_id"
  end

  create_table "set_logs", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "block_exercise_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "set_number", null: false
    t.integer "segment_number", default: 1, null: false
    t.integer "reps_completed"
    t.decimal "load_value", precision: 7, scale: 2
    t.enum "load_unit", enum_type: "load_unit"
    t.integer "duration_seconds"
    t.decimal "distance_value", precision: 9, scale: 2
    t.integer "calories"
    t.decimal "rpe_reported", precision: 3, scale: 1
    t.datetime "completed_at"
    t.boolean "skipped", default: false, null: false
    t.text "notes"
    t.uuid "client_uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_exercise_id"], name: "index_set_logs_on_block_exercise_id"
    t.index ["client_uuid"], name: "index_set_logs_on_client_uuid", unique: true
    t.index ["exercise_id", "completed_at"], name: "index_set_logs_on_exercise_id_and_completed_at", order: { completed_at: :desc }
    t.index ["exercise_id"], name: "index_set_logs_on_exercise_id"
    t.index ["session_id", "block_exercise_id", "set_number", "segment_number"], name: "idx_set_logs_unique", unique: true
    t.index ["session_id"], name: "index_set_logs_on_session_id"
  end

  create_table "users", force: :cascade do |t|
    t.citext "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.enum "role", default: "client", null: false, enum_type: "user_role"
    t.string "locale", default: "es", null: false
    t.string "timezone", default: "America/Bogota", null: false
    t.enum "unit_preference", default: "metric", null: false, enum_type: "unit_system"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "confirmed_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "block_exercise_alternatives", "block_exercises"
  add_foreign_key "block_exercise_alternatives", "exercises"
  add_foreign_key "block_exercises", "exercises"
  add_foreign_key "block_exercises", "program_blocks"
  add_foreign_key "check_ins", "program_assignments"
  add_foreign_key "check_ins", "users", column: "client_id"
  add_foreign_key "client_equipment", "client_profiles"
  add_foreign_key "client_equipment", "equipment_items"
  add_foreign_key "client_injuries", "client_profiles"
  add_foreign_key "client_profiles", "users"
  add_foreign_key "exercises", "equipment_items", column: "default_equipment_item_id"
  add_foreign_key "exercises", "users", column: "practitioner_id"
  add_foreign_key "plan_imports", "program_versions"
  add_foreign_key "plan_imports", "users", column: "practitioner_id"
  add_foreign_key "practitioner_clients", "users", column: "client_id"
  add_foreign_key "practitioner_clients", "users", column: "practitioner_id"
  add_foreign_key "practitioner_profiles", "users"
  add_foreign_key "prescribed_sets", "block_exercises"
  add_foreign_key "prescribed_sets", "equipment_items"
  add_foreign_key "program_assignments", "program_versions"
  add_foreign_key "program_assignments", "users", column: "client_id"
  add_foreign_key "program_assignments", "users", column: "practitioner_id"
  add_foreign_key "program_blocks", "program_blocks", column: "parent_block_id"
  add_foreign_key "program_blocks", "program_days"
  add_foreign_key "program_days", "program_weeks"
  add_foreign_key "program_versions", "plan_imports", column: "source_import_id"
  add_foreign_key "program_versions", "programs"
  add_foreign_key "program_weeks", "program_versions"
  add_foreign_key "programs", "users", column: "practitioner_id"
  add_foreign_key "sessions", "program_assignments"
  add_foreign_key "sessions", "program_days"
  add_foreign_key "set_logs", "block_exercises"
  add_foreign_key "set_logs", "exercises"
  add_foreign_key "set_logs", "sessions"
end
