class EmployeesController < ApplicationController
  def index
    load_index_data

    return render partial: "employees/employees_results", locals: {
      employees: @employees,
      employee_query: @employee_query,
      position_filter: @position_filter
    } if turbo_frame_request? && request.headers["Turbo-Frame"] == "employees_results"
  end

  private

  def load_index_data
    @employee_query = params[:employee_query].to_s.strip
    @position_filter = params[:position].to_s
    @positions = Position.order(:name)

    scope = Employee.includes(:position).order(:id)
    scope = scope.where("employees.name ILIKE ?", "%#{@employee_query}%") if @employee_query.present?
    scope = scope.joins(:position).where(positions: { name: @position_filter }) if @position_filter.present?

    @employees = scope
  end
end