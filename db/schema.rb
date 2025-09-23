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

ActiveRecord::Schema[8.0].define(version: 2025_09_20_170916) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "contacts", force: :cascade do |t|
    t.string "nome", null: false
    t.string "cognome", null: false
    t.string "email", null: false
    t.string "telefono_facoltativo"
    t.boolean "diventa_insegnante", default: false, null: false
    t.integer "tipo_utente", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.string "address"
    t.bigint "user_id"
    t.bigint "responsable_contact_id"
    t.index ["email"], name: "index_contacts_on_email", unique: true
    t.index ["responsable_contact_id"], name: "index_contacts_on_responsable_contact_id"
    t.index ["tipo_utente"], name: "index_contacts_on_tipo_utente"
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "list_id", null: false
    t.string "title"
    t.string "ancestry"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id", "ancestry", "position"], name: "index_items_on_list_id_and_ancestry_and_position"
    t.index ["list_id", "ancestry"], name: "index_items_on_list_id_and_ancestry"
    t.index ["list_id"], name: "index_items_on_list_id"
  end

  create_table "lists", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scheduled_events", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.bigint "training_course_id"
    t.string "lesson_slug"
    t.datetime "start_at"
    t.datetime "end_at"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_scheduled_events_on_contact_id"
    t.index ["lesson_slug"], name: "index_scheduled_events_on_lesson_slug"
    t.index ["training_course_id"], name: "index_scheduled_events_on_training_course_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "training_courses", force: :cascade do |t|
    t.string "course_slug"
    t.bigint "contact_id", null: false
    t.string "version"
    t.datetime "registrations_open_at"
    t.datetime "registrations_close_at"
    t.string "package_slug"
    t.integer "tutor_role_id"
    t.integer "teacher_role_id"
    t.integer "trainee_role_id"
    t.integer "venue_manager_role_id"
    t.text "location_name"
    t.text "location_address"
    t.string "location_gmaps"
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.string "location_phone"
    t.integer "participants_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_training_courses_on_contact_id"
    t.index ["course_slug"], name: "index_training_courses_on_course_slug"
    t.index ["package_slug"], name: "index_training_courses_on_package_slug"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "superadmin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["superadmin"], name: "index_users_on_superadmin"
  end

  add_foreign_key "contacts", "contacts", column: "responsable_contact_id"
  add_foreign_key "contacts", "users"
  add_foreign_key "items", "lists"
  add_foreign_key "scheduled_events", "contacts"
  add_foreign_key "scheduled_events", "training_courses"
  add_foreign_key "sessions", "users"
  add_foreign_key "training_courses", "contacts"
end
