require "test_helper"

class EmployeePayrollCalculatorTest < ActiveSupport::TestCase
  test "calculates payroll with overtime and tax" do
    employee = employees(:somchai)
    employee.update!(salary: BigDecimal("60000"))

    attendances = Attendance.where(id: attendances(:somchai_may_present_ot).id)
    payroll = EmployeePayrollCalculator.new(employee, attendances: attendances)

    assert_equal BigDecimal("60000"), payroll.base_salary
    assert_equal 1, payroll.working_days
    assert_equal BigDecimal("1.5"), payroll.total_ot_hours
    assert_equal BigDecimal("250.0"), payroll.hourly_rate
    assert_equal BigDecimal("375.00"), payroll.ot_pay
    assert_equal BigDecimal("2000.0"), payroll.tax
    assert_equal BigDecimal("58375.00"), payroll.net_pay
  end

  test "calculates zero tax for salary not over 30000" do
    employee = employees(:nida)
    employee.update!(salary: BigDecimal("30000"))

    payroll = EmployeePayrollCalculator.new(employee, attendances: Attendance.none)

    assert_equal BigDecimal("0"), payroll.tax
    assert_equal BigDecimal("30000"), payroll.net_pay
  end

  test "calculates five percent tax only for income between 30001 and 50000" do
    employee = employees(:woranan)
    employee.update!(salary: BigDecimal("45000"))

    payroll = EmployeePayrollCalculator.new(employee, attendances: Attendance.none)

    assert_equal BigDecimal("750.0"), payroll.tax
    assert_equal BigDecimal("44250.0"), payroll.net_pay
  end

  test "aggregates overtime from multiple present attendances and ignores non present records" do
    employee = employees(:somchai)
    employee.update!(salary: BigDecimal("60000"))

    extra_present = Attendance.create!(
      employee: employee,
      work_date: Date.new(2026, 5, 3),
      status: :present,
      check_in: Time.zone.local(2026, 5, 3, 9, 0),
      check_out: Time.zone.local(2026, 5, 3, 20, 0)
    )
    leave_day = attendances(:somchai_may_absent)

    attendances = Attendance.where(id: [ attendances(:somchai_may_present_ot).id, extra_present.id, leave_day.id ])
    payroll = EmployeePayrollCalculator.new(employee, attendances: attendances)

    assert_equal 2, payroll.working_days
    assert_equal BigDecimal("4.5"), payroll.total_ot_hours
    assert_equal BigDecimal("1125.0"), payroll.ot_pay
  end
end
