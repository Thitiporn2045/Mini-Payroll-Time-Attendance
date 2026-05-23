class EmployeesController < ApplicationController
  before_action :set_employee, only: [ :show, :edit, :update, :destroy, :confirm_destroy ]
  before_action :set_positions, only: [ :new, :create, :edit, :update ]

  def index
    load_index_data
    render partial: "employees/employees_results", locals: {
      employees: @employees,
      employee_query: @employee_query,
      position_filter: @position_filter
    } if turbo_frame_request? && request.headers["Turbo-Frame"] == "employees_results"
  end

  def show
    prepare_show_data
    render partial: "employees/attendance_table_frame", locals: {
      employee: @employee,
      attendances: @attendances,
      selected_month_value: @selected_month_value,
      selected_month_label: @selected_month_label,
      status_filter: @attendance_status_filter
    } if turbo_frame_request? && request.headers["Turbo-Frame"] == "attendance_table"
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
          redirect_to(params[:return_to] == "employees" ? employees_path(employee_query: params[:employee_query], position: params[:position]) : employee_path(@employee, month: params[:month], status: params[:status]), notice: "เพิ่มข้อมูลพนักงานเรียบร้อยแล้ว")
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

  def confirm_destroy
  end

  def update
    position = Position.find_or_create_by_name!(employee_params[:position_name])

    @employee.assign_attributes(employee_params.except(:position_name))
    @employee.position = position

    if @employee.save
      prepare_show_data if params[:return_to] == "employee"
      load_index_data if params[:return_to] == "employees"

      respond_to do |format|
        format.html do
          redirect_to(params[:return_to] == "employees" ? employees_path(employee_query: params[:employee_query], position: params[:position]) : employee_path(@employee, month: params[:month], status: params[:status]), notice: "อัปเดตข้อมูลพนักงานเรียบร้อยแล้ว")
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

  def destroy
    @employee.destroy

    if params[:return_to] == "employees"
      load_index_data

      respond_to do |format|
        format.html do
          redirect_to employees_path(employee_query: params[:employee_query], position: params[:position]), notice: "ลบข้อมูลพนักงานเรียบร้อยแล้ว", status: :see_other
        end

        format.turbo_stream
      end
    elsif params[:return_to] == "employee_show"
      respond_to do |format|
        format.html do
          redirect_to employees_path, notice: "ลบข้อมูลพนักงานเรียบร้อยแล้ว", status: :see_other
        end

        format.turbo_stream do
          redirect_to employees_path, notice: "ลบข้อมูลพนักงานเรียบร้อยแล้ว", status: :see_other
        end
      end
    else
      @employees = Employee.includes(:position).order(:id)

      respond_to do |format|
        format.html do
          redirect_to employees_path, notice: "ลบข้อมูลพนักงานเรียบร้อยแล้ว", status: :see_other
        end

        format.turbo_stream
      end
    end
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

  def prepare_show_data
    @selected_month = resolve_selected_month
    month_range = @selected_month.all_month
    @attendance_status_filter = params[:status].to_s

    monthly_attendances = @employee.attendances.where(work_date: month_range).order(work_date: :desc)
    @payroll = EmployeePayrollCalculator.new(@employee, attendances: monthly_attendances)
    @attendances = monthly_attendances
    @attendances = @attendances.public_send("status_#{@attendance_status_filter}") if @attendance_status_filter.present? && Attendance.statuses.key?(@attendance_status_filter)
    @selected_month_value = @selected_month.strftime("%Y-%m")
    @selected_month_label = @selected_month.strftime("%m/%Y")
    @employees_for_select = Employee.order(:name)
  end

  def resolve_selected_month
    month_param = params[:month].to_s
    return Date.current.beginning_of_month if month_param.blank?

    Date.strptime("#{month_param}-01", "%Y-%m-%d")
  rescue ArgumentError
    Date.current.beginning_of_month
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
