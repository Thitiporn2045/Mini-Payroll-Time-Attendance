module EmployeeShowContext
  private

  def prepare_employee_show_context(employee)
    @selected_month = resolve_selected_month
    @attendance_status_filter = params[:status].to_s

    monthly_attendances = employee.attendances
      .where(work_date: @selected_month.all_month)
      .order(work_date: :desc)

    @payroll = EmployeePayrollCalculator.new(employee, attendances: monthly_attendances)
    @attendances = filter_attendances_by_status(monthly_attendances, @attendance_status_filter)
    @selected_month_value = @selected_month.strftime("%Y-%m")
    @selected_month_label = @selected_month.strftime("%m/%Y")
    @selected_month_title = helpers.thai_month_title(@selected_month)
    @employees_for_select = Employee.order(:name)
  end

  def resolve_selected_month
    month_param = params[:month].to_s
    return Date.current.beginning_of_month if month_param.blank?

    Date.strptime("#{month_param}-01", "%Y-%m-%d")
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def filter_attendances_by_status(scope, status_filter)
    return scope unless status_filter.present? && Attendance.statuses.key?(status_filter)

    scope.public_send("status_#{status_filter}")
  end
end
