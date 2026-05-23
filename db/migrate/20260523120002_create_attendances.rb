class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :work_date, null: false
      t.integer :status, null: false
      t.datetime :check_in
      t.datetime :check_out

      t.timestamps
    end

    add_index :attendances, [:employee_id, :work_date], unique: true

    add_check_constraint :attendances,
      "status IN (0, 1, 2)",
      name: "attendance_status_check"

    add_check_constraint :attendances,
      "(check_in IS NULL OR DATE(check_in) = work_date)",
      name: "attendance_check_in_same_work_date"

    add_check_constraint :attendances,
      "(check_out IS NULL OR DATE(check_out) = work_date)",
      name: "attendance_check_out_same_work_date"

    add_check_constraint :attendances,
      "(check_in IS NULL OR check_out IS NULL OR check_out > check_in)",
      name: "attendance_check_out_after_check_in"
  end
end