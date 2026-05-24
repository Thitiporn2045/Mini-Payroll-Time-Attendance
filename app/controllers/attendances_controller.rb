class AttendancesController < ApplicationController
  include EmployeeShowContext

  before_action :set_employee, only: [ :edit, :update ]
  before_action :set_attendance, only: [ :edit, :update ]
  before_action :load_workspace_data, only: [ :index ]

  def index
    render partial: "attendances/workspace_results", locals: {
      attendances: @attendance_records,
      employee_query: @employee_query,
      status_filter: @status_filter
    } if turbo_frame_request? && request.headers["Turbo-Frame"] == "attendance_workspace_results"
  end

  def new
    if workspace_context?
      load_workspace_data
      @attendance = Attendance.new(
        work_date: Date.current,
        status: :present
      )
    else
      set_employee
      @attendance = @employee.attendances.new(
        work_date: Date.current,
        status: :present
      )
    end
  end

  def create
    if workspace_context?
      load_workspace_data
      @employee = Employee.find_by(id: attendance_params[:employee_id])

      if @employee.blank?
        @attendance = Attendance.new(filtered_attendance_params)
        @attendance.errors.add(:employee_id, "กรุณาเลือกพนักงาน")
        render :new, status: :unprocessable_entity
        return
      end

      @attendance = @employee.attendances.new(filtered_attendance_params)
    else
      set_employee
      @attendance = @employee.attendances.new(filtered_attendance_params)
    end

    if @attendance.save
      if workspace_context?
        saved_work_date = @attendance.work_date
        load_workspace_data
        @attendance = Attendance.new(
          work_date: saved_work_date,
          status: :present
        )
      else
        prepare_employee_show_data
      end

      respond_to do |format|
        format.html do
          redirect_to(workspace_context? ? attendances_path(workspace_redirect_params) : employee_path(@employee, month: params[:month], status: params[:status]), notice: "เพิ่มข้อมูลเวลาเข้าออกงานเรียบร้อยแล้ว")
        end

        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_workspace_data if workspace_context?
  end

  def update
    if @attendance.update(filtered_attendance_params)
      workspace_context? ? load_workspace_data : prepare_employee_show_data

      respond_to do |format|
        format.html do
          redirect_to(workspace_context? ? attendances_path(workspace_redirect_params) : employee_path(@employee, month: params[:month], status: params[:status]), notice: "อัปเดตข้อมูลเวลาเข้าออกงานเรียบร้อยแล้ว")
        end

        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:employee_id])
  end

  def set_attendance
    @attendance = @employee.attendances.find(params[:id])
  end

  def load_workspace_data
    @employees = Employee.includes(:position).order(:name)
    @employee_query = params[:employee_query].to_s.strip
    @status_filter = params[:status].to_s

    scope = Attendance.includes(employee: :position).order(work_date: :desc, created_at: :desc)

    if @employee_query.present?
      scope = scope.joins(:employee).where("employees.name ILIKE ?", "%#{@employee_query}%")
    end

    if @status_filter.present? && Attendance.statuses.key?(@status_filter)
      scope = scope.public_send("status_#{@status_filter}")
    end

    @attendance_records = scope
  end

  def workspace_context?
    params[:return_to] == "workspace" || (params[:controller] == "attendances" && params[:employee_id].blank?)
  end

  def workspace_redirect_params
    {
      employee_query: params[:employee_query].presence,
      status: params[:status].presence
    }.compact
  end

  def filtered_attendance_params
    attrs = attendance_params.to_h.symbolize_keys.except(:employee_id)
    work_date = attrs[:work_date].presence

    attrs[:check_in] = combine_date_and_time(work_date, attrs[:check_in])
    attrs[:check_out] = combine_date_and_time(work_date, attrs[:check_out])
    attrs
  end

  def attendance_params
    params.require(:attendance).permit(:employee_id, :work_date, :status, :check_in, :check_out)
  end

  def combine_date_and_time(work_date, time_value)
    return nil if work_date.blank? || time_value.blank?

    Time.zone.parse("#{work_date} #{time_value}")
  end

  def prepare_employee_show_data
    prepare_employee_show_context(@employee)
  end
end
