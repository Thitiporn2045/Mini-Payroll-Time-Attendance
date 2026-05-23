require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  UNSET = Object.new

  test "is valid with fixture data" do
    assert attendances(:somchai_may_present_ot).valid?
  end

  test "requires work_date" do
    attendance = Attendance.new(
      employee: employees(:somchai),
      work_date: nil,
      status: :present,
      check_in: time_on(Date.new(2026, 6, 1), 9, 0),
      check_out: time_on(Date.new(2026, 6, 1), 18, 0)
    )

    assert_not attendance.valid?
    assert_includes attendance.errors[:work_date], I18n.t("errors.messages.blank")
  end

  test "requires unique work_date per employee" do
    attendance = build_present_attendance(work_date: attendances(:somchai_may_present_ot).work_date)

    assert_not attendance.valid?
    assert_includes attendance.errors[:work_date], I18n.t("errors.messages.taken")
  end

  test "requires check_in when present" do
    attendance = build_present_attendance(check_in: nil, check_out: time_on(Date.new(2026, 6, 1), 18, 0))

    assert_not attendance.valid?
    assert_includes attendance.errors[:check_in], I18n.t("errors.messages.blank")
  end

  test "requires check_out when present" do
    attendance = build_present_attendance(check_in: time_on(Date.new(2026, 6, 1), 9, 0), check_out: nil)

    assert_not attendance.valid?
    assert_includes attendance.errors[:check_out], I18n.t("errors.messages.blank")
  end

  test "clears times for leave status" do
    attendance = Attendance.new(
      employee: employees(:somchai),
      work_date: Date.new(2026, 6, 2),
      status: :leave,
      check_in: time_on(Date.new(2026, 6, 2), 9, 0),
      check_out: time_on(Date.new(2026, 6, 2), 18, 0)
    )

    assert attendance.valid?
    assert_nil attendance.check_in
    assert_nil attendance.check_out
  end

  test "check_in must be on work_date" do
    attendance = build_present_attendance(check_in: time_on(Date.new(2026, 6, 2), 9, 0))

    assert_not attendance.valid?
    assert_includes attendance.errors[:check_in], "ต้องเป็นเวลาในวันทำงานเดียวกัน"
  end

  test "check_out must be on work_date" do
    attendance = build_present_attendance(check_out: time_on(Date.new(2026, 6, 2), 18, 0))

    assert_not attendance.valid?
    assert_includes attendance.errors[:check_out], "ต้องเป็นเวลาในวันทำงานเดียวกัน"
  end

  test "check_out must be after check_in" do
    date = Date.new(2026, 6, 1)
    attendance = build_present_attendance(
      check_in: time_on(date, 18, 0),
      check_out: time_on(date, 17, 0)
    )

    assert_not attendance.valid?
    assert_includes attendance.errors[:check_out], "ต้องเป็นเวลาหลังเวลาเข้า"
  end

  test "worked_hours returns rounded decimal hours for present attendance" do
    date = Date.new(2026, 6, 1)
    attendance = build_present_attendance(
      check_in: time_on(date, 9, 0),
      check_out: time_on(date, 17, 45)
    )

    assert_equal BigDecimal("8.75"), attendance.worked_hours
  end

  test "worked_hours returns zero for non present attendance" do
    assert_equal BigDecimal("0"), attendances(:woranan_may_leave).worked_hours
    assert_equal BigDecimal("0"), attendances(:somchai_may_absent).worked_hours
  end

  test "worked_hours returns zero when times are blank" do
    attendance = Attendance.new(
      employee: employees(:somchai),
      work_date: Date.new(2026, 6, 1),
      status: :present
    )

    assert_equal BigDecimal("0"), attendance.worked_hours
  end

  test "ot_hours returns hours above eight only" do
    assert_equal BigDecimal("1.5"), attendances(:somchai_may_present_ot).ot_hours
    assert_equal BigDecimal("0"), attendances(:nida_may_present_short).ot_hours
  end

  test "status_label returns translated label" do
    assert_equal "มาทำงาน", attendances(:somchai_may_present_ot).status_label
    assert_equal "ลา", attendances(:woranan_may_leave).status_label
    assert_equal "ขาด", attendances(:somchai_may_absent).status_label
  end

  private

  def build_present_attendance(work_date: Date.new(2026, 6, 1), check_in: UNSET, check_out: UNSET)
    Attendance.new(
      employee: employees(:somchai),
      work_date: work_date,
      status: :present,
      check_in: check_in.equal?(UNSET) ? time_on(work_date, 9, 0) : check_in,
      check_out: check_out.equal?(UNSET) ? time_on(work_date, 18, 0) : check_out
    )
  end

  def time_on(date, hour, minute)
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end
end
