class EmployeesController < ApplicationController
  before_action :load_positions, only: [:new, :create]
  def index
    load_index_data

    return render partial: "employees/employees_results", locals: {
      employees: @employees,
      employee_query: @employee_query,
      position_filter: @position_filter
    } if turbo_frame_request? && request.headers["Turbo-Frame"] == "employees_results"
  end

  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params.except(:position_name))
    assign_position_from_params

    if @employee.save
      redirect_to employees_path, notice: "เพิ่มพนักงานเรียบร้อยแล้ว"
    else
      render :new, status: :unprocessable_entity
    end
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

  def load_positions
    @positions = Position.order(:name)
  end

  def assign_position_from_params
    raw_position_name = employee_params[:position_name].to_s.strip

    if raw_position_name.present?
      @employee.position = Position.find_or_create_by_name!(raw_position_name)
    end
  end

  def employee_params
    params.require(:employee).permit(:name, :salary, :position_id, :position_name)
  end
end