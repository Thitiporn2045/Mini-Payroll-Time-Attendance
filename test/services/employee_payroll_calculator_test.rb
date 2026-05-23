require "test_helper"

class EmployeePayrollCalculatorTest < ActiveSupport::TestCase
  test "calculates payroll with overtime and tax" do
    employee = employees(:gift)
    employee.update!(salary: BigDecimal("60000"))

    attendances = Attendance.where(id: attendances(:gift_present).id)
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
    employee = employees(:gift)
    employee.update!(salary: BigDecimal("30000"))

    payroll = EmployeePayrollCalculator.new(employee, attendances: Attendance.none)

    assert_equal BigDecimal("0"), payroll.tax
    assert_equal BigDecimal("30000"), payroll.net_pay
  end
end