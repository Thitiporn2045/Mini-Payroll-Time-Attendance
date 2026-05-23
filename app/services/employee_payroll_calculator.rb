class EmployeePayrollCalculator
  WORKING_DAYS_PER_MONTH = BigDecimal("30")
  REGULAR_HOURS_PER_DAY = BigDecimal("8")

  attr_reader :employee, :attendances

  def initialize(employee, attendances: employee.attendances)
    @employee = employee
    @attendances = attendances
  end

  def base_salary
    employee.salary
  end

  def working_days
    present_attendances.count
  end

  def total_ot_hours
    present_attendances.sum { |attendance| attendance.ot_hours }
  end

  def hourly_rate
    base_salary / WORKING_DAYS_PER_MONTH / REGULAR_HOURS_PER_DAY
  end

  def ot_pay
    total_ot_hours * hourly_rate
  end

  def tax
    if base_salary <= BigDecimal("30000")
      BigDecimal("0")
    elsif base_salary <= BigDecimal("50000")
      (base_salary - BigDecimal("30000")) * BigDecimal("0.05")
    else
      (BigDecimal("20000") * BigDecimal("0.05")) +
        ((base_salary - BigDecimal("50000")) * BigDecimal("0.10"))
    end
  end

  def net_pay
    base_salary + ot_pay - tax
  end

  private

  def present_attendances
    attendances.status_present
  end
end
