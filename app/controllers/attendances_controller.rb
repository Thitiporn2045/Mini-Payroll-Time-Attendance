class AttendancesController < ApplicationController
  before_action :set_employee, only: [ :new, :create, :edit, :update ]
  before_action :set_attendance, only: [ :edit, :update ]

  def index
    @selected_month = resolve_selected_month
    @selected_month_value = @selected_month.strftime("%Y-%m")
    @status_filter = params[:status].to_s
    @employee_filter = params[:employee_id].to_s

    @employees = Employee.order(:name)

    scope = Attendance.includes(employee: :position)
      .where(work_date: @selected_month.all_month)
      .order(work_date: :desc, id: :desc)

    if @status_filter.present? && Attendance.statuses.key?(@status_filter)
      scope = scope.public_send("status_#{@status_filter}")
    end

    if @employee_filter.present?
      scope = scope.where(employee_id: @employee_filter)
    end

    @attendances = scope
  end

  def new
    @attendance = @employee.attendances.new(
      work_date: selected_month_for_default,
      status: :present
    )
  end

  def create
    @attendance = @employee.attendances.new(filtered_attendance_params)

    if @attendance.save
      prepare_employee_show_data

      respond_to do |format|
        format.html do
          redirect_to employee_path(@employee, month: params[:month], status: params[:status]),
            notice: "เพิ่มข้อมูลเวลาเข้าออกงานเรียบร้อยแล้ว"
        end

        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @attendance.update(filtered_attendance_params)
      prepare_employee_show_data

      respond_to do |format|
        format.html do
          redirect_to employee_path(@employee, month: params[:month], status: params[:status]),
            notice: "อัปเดตข้อมูลเวลาเข้าออกงานเรียบร้อยแล้ว"
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

  def filtered_attendance_params
    attrs = attendance_params.to_h.symbolize_keys

    work_date = attrs[:work_date].presence
    attrs[:check_in] = combine_date_and_time(work_date, attrs[:check_in])
    attrs[:check_out] = combine_date_and_time(work_date, attrs[:check_out])

    attrs
  end

  def attendance_params
    params.require(:attendance).permit(:work_date, :status, :check_in, :check_out)
  end

  def combine_date_and_time(work_date, time_value)
    return nil if work_date.blank? || time_value.blank?

    Time.zone.parse("#{work_date} #{time_value}")
  end

  def prepare_employee_show_data
    selected_month = resolve_selected_month
    month_range = selected_month.all_month
    @attendance_status_filter = params[:status].to_s

    monthly_attendances = @employee.attendances
      .where(work_date: month_range)
      .order(work_date: :desc)

    @payroll = EmployeePayrollCalculator.new(@employee, attendances: monthly_attendances)
    @attendances = monthly_attendances

    if @attendance_status_filter.present? && Attendance.statuses.key?(@attendance_status_filter)
      @attendances = @attendances.public_send("status_#{@attendance_status_filter}")
    end

    @selected_month_value = selected_month.strftime("%Y-%m")
    @selected_month_label = selected_month.strftime("%m/%Y")
  end

  def resolve_selected_month
    month_param = params[:month].to_s
    return Date.current.beginning_of_month if month_param.blank?

    Date.strptime("#{month_param}-01", "%Y-%m-%d")
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def selected_month_for_default
    resolve_selected_month
  end
end
