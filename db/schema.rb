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

ActiveRecord::Schema[8.1].define(version: 2026_05_23_120002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.datetime "check_in"
    t.datetime "check_out"
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.integer "status", null: false
    t.datetime "updated_at", null: false
    t.date "work_date", null: false
    t.index ["employee_id", "work_date"], name: "index_attendances_on_employee_id_and_work_date", unique: true
    t.index ["employee_id"], name: "index_attendances_on_employee_id"
    t.check_constraint "check_in IS NULL OR check_out IS NULL OR check_out > check_in", name: "attendance_check_out_after_check_in"
    t.check_constraint "check_in IS NULL OR date(check_in) = work_date", name: "attendance_check_in_same_work_date"
    t.check_constraint "check_out IS NULL OR date(check_out) = work_date", name: "attendance_check_out_same_work_date"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2])", name: "attendance_status_check"
  end

  create_table "employees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "position_id", null: false
    t.decimal "salary", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_employees_on_name"
    t.index ["position_id"], name: "index_employees_on_position_id"
  end

  create_table "positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized_name"], name: "index_positions_on_normalized_name", unique: true
  end

  add_foreign_key "attendances", "employees"
  add_foreign_key "employees", "positions"
end
