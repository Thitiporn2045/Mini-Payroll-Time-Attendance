require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  test "is valid with present status and valid times" do
    attendance = Attendance.new(
      employee: employees(:gift),
      work_date: Date.new(2026, 5, 3),
      status: :present,
      check_in: Time.zone.local(2026, 5, 3, 9, 0),
      check_out: Time.zone.local(2026, 5, 3, 18, 0)
    )

    assert attendance.valid?
  end

  test "requires check in and check out when present" do
    attendance = Attendance.new(
      employee: employees(:gift),
      work_date: Date.new(2026, 5, 3),
      status: :present
    )

    assert_not attendance.valid?
    assert attendance.errors.added?(:check_in, :blank)
    assert attendance.errors.added?(:check_out, :blank)
  end

  test "clears times when status is leave" do
    attendance = Attendance.new(
      employee: employees(:gift),
      work_date: Date.new(2026, 5, 3),
      status: :leave,
      check_in: Time.zone.local(2026, 5, 3, 9, 0),
      check_out: Time.zone.local(2026, 5, 3, 18, 0)
    )

    assert attendance.valid?
    assert_nil attendance.check_in
    assert_nil attendance.check_out
  end

  test "is invalid when check out is before check in" do
    attendance = Attendance.new(
      employee: employees(:gift),
      work_date: Date.new(2026, 5, 3),
      status: :present,
      check_in: Time.zone.local(2026, 5, 3, 18, 0),
      check_out: Time.zone.local(2026, 5, 3, 9, 0)
    )

    assert_not attendance.valid?
    assert attendance.errors[:check_out].present?
  end

  test "is invalid when check in is not on work date" do
    attendance = Attendance.new(
      employee: employees(:gift),
      work_date: Date.new(2026, 5, 3),
      status: :present,
      check_in: Time.zone.local(2026, 5, 2, 9, 0),
      check_out: Time.zone.local(2026, 5, 3, 18, 0)
    )

    assert_not attendance.valid?
    assert attendance.errors[:check_in].present?
  end

  test "does not allow duplicate work date for the same employee" do
    attendance = Attendance.new(
      employee: employees(:gift),
      work_date: Date.new(2026, 5, 1),
      status: :present,
      check_in: Time.zone.local(2026, 5, 1, 8, 0),
      check_out: Time.zone.local(2026, 5, 1, 17, 0)
    )

    assert_not attendance.valid?
    assert_includes attendance.errors.details[:work_date], { error: :taken, value: Date.new(2026, 5, 1) }
  end

  test "allows the same work date for a different employee" do
    attendance = Attendance.new(
      employee: employees(:mild),
      work_date: Date.new(2026, 5, 2),
      status: :present,
      check_in: Time.zone.local(2026, 5, 2, 8, 0),
      check_out: Time.zone.local(2026, 5, 2, 17, 0)
    )

    assert attendance.valid?
  end

  test "calculates worked hours" do
    attendance = attendances(:gift_present)

    assert_equal BigDecimal("9.5"), attendance.worked_hours
  end

  test "calculates ot hours" do
    attendance = attendances(:gift_present)

    assert_equal BigDecimal("1.5"), attendance.ot_hours
  end
end
