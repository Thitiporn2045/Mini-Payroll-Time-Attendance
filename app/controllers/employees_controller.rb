class EmployeesController < ApplicationController
  before_action :set_employee, only: [:edit, :update]
  before_action :set_positions, only: [:new, :create, :edit, :update]

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
    position = Position.find_or_create_by_name!(employee_params[:position_name])

    @employee = Employee.new(employee_params.except(:position_name))
    @employee.position = position

    if @employee.save
      load_index_data if params[:return_to] == "employees"

      respond_to do |format|
        format.html do
          redirect_to employees_path(
            employee_query: params[:employee_query],
            position: params[:position]
          ), notice: "เพิ่มข้อมูลพนักงานเรียบร้อยแล้ว"
        end

        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => error
    @employee ||= Employee.new(employee_params.except(:position_name))
    @employee.position_name = employee_params[:position_name]
    copy_position_errors(error.record)

    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    position = Position.find_or_create_by_name!(employee_params[:position_name])

    @employee.assign_attributes(employee_params.except(:position_name))
    @employee.position = position

    if @employee.save
      load_index_data if params[:return_to] == "employees"

      respond_to do |format|
        format.html do
          redirect_to employees_path(
            employee_query: params[:employee_query],
            position: params[:position]
          ), notice: "อัปเดตข้อมูลพนักงานเรียบร้อยแล้ว"
        end

        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => error
    @employee.position_name = employee_params[:position_name]
    copy_position_errors(error.record)

    render :edit, status: :unprocessable_entity
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def set_positions
    @positions = Position.order(:name)
  end

  def employee_params
    params.require(:employee).permit(:name, :salary, :position_name)
  end

  def load_index_data
    @employee_query = params[:employee_query].to_s.strip
    @position_filter = params[:position].to_s
    @positions = Position.order(:name)

    scope = Employee.includes(:position).order(:id)
    scope = scope.where("employees.name ILIKE ?", "%#{@employee_query}%") if @employee_query.present?
    scope = scope.joins(:position).where(positions: { name: @position_filter }) if @position_filter.present?

    @employees = scope
  end

  def copy_position_errors(position)
    position.errors.each do |error|
      @employee.errors.add(:position_name, error.type, **error.options.except(:value))
    end
  end
end