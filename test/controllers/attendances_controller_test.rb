require "test_helper"

class AttendancesControllerTest < ActionDispatch::IntegrationTest
  test "shows attendance index without employee id" do
    get attendances_path

    assert_response :success
    assert_select "h1.page-title", "ข้อมูลเวลาเข้าออกงาน"
    assert_select "#attendance_workspace_table td", /#{Regexp.escape(employees(:somchai).name)}/
  end

  test "shows centered empty state when attendance workspace has no data" do
    Attendance.delete_all

    get attendances_path

    assert_response :success
    assert_select "turbo-frame#attendance_workspace_results .empty-state-balanced"
    assert_select ".empty-state-balanced .empty-title", "ยังไม่มีข้อมูลเวลาเข้าออกงาน"
  end

  test "filters attendance index by employee query and status" do
    get attendances_path, params: { employee_query: "Wor", status: "leave" }

    assert_response :success
    assert_select "turbo-frame#attendance_workspace_results td", /#{Regexp.escape(employees(:woranan).name)}/
    assert_select "turbo-frame#attendance_workspace_results td", text: /#{Regexp.escape(employees(:somchai).name)}/, count: 0
    assert_select "turbo-frame#attendance_workspace_results span", text: attendances(:woranan_may_leave).status_label
    assert_select "turbo-frame#attendance_workspace_results span", text: attendances(:somchai_may_present_ot).status_label, count: 0
  end

  test "renders workspace results partial for turbo frame requests" do
    get attendances_path, headers: { "Turbo-Frame" => "attendance_workspace_results" }

    assert_response :success
    assert_select "turbo-frame#attendance_workspace_results"
    assert_select "h1", count: 0
  end

  test "shows workspace new attendance form with employee selector" do
    get new_attendance_path(return_to: "workspace")

    assert_response :success
    assert_select "select[name='attendance[employee_id]']"
  end

  test "edit form hides time fields for leave attendance" do
    get edit_employee_attendance_path(employees(:woranan), attendances(:woranan_may_leave))

    assert_response :success
    assert_select "[data-attendance-form-target='timeFields'].hidden"
  end

  test "edit form shows time fields for present attendance" do
    get edit_employee_attendance_path(employees(:somchai), attendances(:somchai_may_present_ot))

    assert_response :success
    assert_select "[data-attendance-form-target='timeFields']:not(.hidden)"
  end

  test "requires employee selection when creating attendance from workspace" do
    assert_no_difference("Attendance.count") do
      post attendances_path, params: {
        return_to: "workspace",
        attendance: {
          employee_id: "",
          work_date: "2026-05-03",
          status: "present",
          check_in: "09:00",
          check_out: "18:00"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-box", /กรุณาเลือกพนักงาน/
  end

  test "creates attendance from workspace context and redirects back to workspace" do
    assert_difference("Attendance.count", 1) do
      post attendances_path, params: {
        return_to: "workspace",
        employee_query: "Som",
        status: "present",
        attendance: {
          employee_id: employees(:somchai).id,
          work_date: "2026-05-03",
          status: "present",
          check_in: "09:00",
          check_out: "19:00"
        }
      }
    end

    attendance = Attendance.order(:id).last

    assert_redirected_to attendances_path(employee_query: "Som", status: "present")
    assert_equal employees(:somchai), attendance.employee
    assert_equal Time.zone.local(2026, 5, 3, 9, 0), attendance.check_in
    assert_equal Time.zone.local(2026, 5, 3, 19, 0), attendance.check_out
  end

  test "does not create duplicate attendance for the same employee and work date" do
    assert_no_difference("Attendance.count") do
      post attendances_path, params: {
        return_to: "workspace",
        attendance: {
          employee_id: employees(:somchai).id,
          work_date: "2026-05-27",
          status: "present",
          check_in: "09:00",
          check_out: "18:00"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-box", /วันที่ทำงาน/i
    assert_select ".error-box", /มีอยู่แล้ว/
  end

  test "does not create attendance when check out is not after check in" do
    assert_no_difference("Attendance.count") do
      post attendances_path, params: {
        return_to: "workspace",
        attendance: {
          employee_id: employees(:somchai).id,
          work_date: "2026-05-03",
          status: "present",
          check_in: "18:00",
          check_out: "17:00"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-box", /ต้องเป็นเวลาหลังเวลาเข้า/
  end

  test "creates attendance from employee detail context and redirects back to employee" do
    employee = employees(:somchai)

    assert_difference("Attendance.count", 1) do
      post employee_attendances_path(employee), params: {
        month: "2026-05",
        status: "present",
        attendance: {
          work_date: "2026-05-04",
          status: "present",
          check_in: "09:00",
          check_out: "18:00"
        }
      }
    end

    assert_redirected_to employee_path(employee, month: "2026-05", status: "present")
  end

  test "creates attendance from employee detail with turbo stream and refreshes Thai month context" do
    employee = employees(:somchai)

    assert_difference("Attendance.count", 1) do
      post employee_attendances_path(employee), params: {
        month: "2026-06",
        status: "present",
        attendance: {
          work_date: "2026-06-04",
          status: "present",
          check_in: "09:00",
          check_out: "18:30"
        }
      }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_select "turbo-stream[target='payroll_summary_header']", text: /มิถุนายน 2026/
    assert_select "turbo-stream[target='payroll_summary_header'] input[type='month'][name='month'][value='2026-06']"
    assert_select "turbo-stream[target='payroll_summary_header'] a", text: "← เดือนก่อนหน้า", count: 0
    assert_select "turbo-stream[target='payroll_summary_header'] a", text: "เดือนถัดไป →", count: 0
    assert_select "turbo-stream[target='attendance_table'] .section-description", /มิถุนายน 2026/
    assert_select "turbo-stream[target='payroll_summary'] .summary-month-label", /มิถุนายน 2026/
  end

  test "updates attendance from workspace context and keeps times cleared for leave" do
    attendance = attendances(:somchai_may_present_ot)

    patch employee_attendance_path(employees(:somchai), attendance), params: {
      return_to: "workspace",
      employee_query: "Som",
      status: "present",
      attendance: {
        work_date: "2026-05-27",
        status: "leave",
        check_in: "09:00",
        check_out: "18:00"
      }
    }

    assert_redirected_to attendances_path(employee_query: "Som", status: "present")
    attendance.reload
    assert_equal "leave", attendance.status
    assert_nil attendance.check_in
    assert_nil attendance.check_out
  end

  test "does not update attendance to a duplicate work date for the same employee" do
    attendance = attendances(:somchai_may_present_regular)

    patch employee_attendance_path(employees(:somchai), attendance), params: {
      month: "2026-05",
      status: "present",
      attendance: {
        work_date: "2026-05-27",
        status: "present",
        check_in: "09:00",
        check_out: "18:00"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".error-box", /วันที่ทำงาน/i
    assert_select ".error-box", /มีอยู่แล้ว/
    attendance.reload
    assert_equal Date.new(2026, 5, 28), attendance.work_date
  end

  test "does not update attendance when check out is not after check in" do
    attendance = attendances(:somchai_may_present_ot)

    patch employee_attendance_path(employees(:somchai), attendance), params: {
      month: "2026-05",
      status: "present",
      attendance: {
        work_date: "2026-05-27",
        status: "present",
        check_in: "18:00",
        check_out: "17:00"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".error-box", /ต้องเป็นเวลาหลังเวลาเข้า/
    attendance.reload
    assert_equal Time.zone.local(2026, 5, 27, 9, 0), attendance.check_in
    assert_equal Time.zone.local(2026, 5, 27, 18, 30), attendance.check_out
  end
end
